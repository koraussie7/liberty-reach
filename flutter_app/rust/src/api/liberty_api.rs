use crate::p2p::swarm::P2PSwarm;
use crate::ai::localai::LocalAIClient;
use crate::storage::sqlite::SqliteStorage;
use crate::blockchain::minima_service::MinimaService;
use crate::reward::reward_service::{RewardService, ActionType};
use std::sync::Arc;
use tokio::sync::RwLock;

static INSTANCE: once_cell::sync::Lazy<Arc<RwLock<LibertyCore>>> =
    once_cell::sync::Lazy::new(|| {
        Arc::new(RwLock::new(LibertyCore::new()))
    });

pub struct LibertyCore {
    pub swarm: Option<Arc<RwLock<P2PSwarm>>>,
    pub ai: Option<LocalAIClient>,
    pub storage: Option<Arc<RwLock<SqliteStorage>>>,
    pub reward: Option<RewardService>,
    pub peer_name: String,
    pub is_initialized: bool,
}

impl LibertyCore {
    fn new() -> Self {
        Self {
            swarm: None,
            ai: None,
            storage: None,
            reward: None,
            peer_name: String::new(),
            is_initialized: false,
        }
    }
}

/// Initialize the Liberty Reach core.
/// Must be called once before any other function.
#[flutter_rust_bridge::frb]
pub async fn init(peer_name: String, localai_url: String, storage_path: String) -> String {
    let mut core = INSTANCE.write().await;

    let storage = match SqliteStorage::new(&storage_path) {
        Ok(s) => Arc::new(RwLock::new(s)),
        Err(e) => return format!("Storage error: {}", e),
    };

    let ai = LocalAIClient::new(localai_url);

    let swarm = match P2PSwarm::new(
        Arc::new(peer_name.clone()),
        8000,
        None,
    ).await {
        Ok(s) => Arc::new(RwLock::new(s)),
        Err(e) => return format!("P2P error: {}", e),
    };

    core.swarm = Some(swarm);
    core.ai = Some(ai);
    core.storage = Some(storage);
    core.peer_name = peer_name.clone();
    core.is_initialized = true;

    format!("Liberty Reach initialized as {}", peer_name)
}

/// Get the local Peer ID
#[flutter_rust_bridge::frb]
pub async fn get_peer_id() -> String {
    let core = INSTANCE.read().await;
    match &core.swarm {
        Some(swarm) => swarm.read().await.local_peer_id().to_string(),
        None => "not initialized".to_string(),
    }
}

/// Get a list of connected peers
#[flutter_rust_bridge::frb]
pub async fn get_connected_peers() -> Vec<String> {
    let core = INSTANCE.read().await;
    match &core.swarm {
        Some(swarm) => {
            let peers = swarm.read().await.get_connected_peers();
            peers.iter().map(|p| p.to_string()).collect()
        }
        None => vec![],
    }
}

/// Send a chat message to the P2P network
#[flutter_rust_bridge::frb]
pub async fn send_message(content: String) -> String {
    let core = INSTANCE.read().await;
    if !core.is_initialized {
        return "not initialized".to_string();
    }

    let peer_name = core.peer_name.clone();
    let msg = serde_json::json!({
        "type": "chat",
        "sender": peer_name,
        "content": content,
        "timestamp": chrono::Utc::now().to_rfc3339(),
    });

    if let Some(swarm) = &core.swarm {
        let mut s = swarm.write().await;
        match s.publish_message(&msg.to_string()) {
            Ok(_) => {
                if let Some(storage) = &core.storage {
                    let _ = storage.write().await.save_message(&peer_name, &content, false);
                }
                content
            }
            Err(e) => format!("send error: {}", e),
        }
    } else {
        "swarm not available".to_string()
    }
}

/// Ask the AI with text (Gemma via LocalAI)
#[flutter_rust_bridge::frb]
pub async fn ask_ai(prompt: String) -> String {
    let core = INSTANCE.read().await;
    match &core.ai {
        Some(ai) => match ai.generate(&prompt).await {
            Ok(response) => {
                if let Some(storage) = &core.storage {
                    let _ = storage.write().await.save_message("AI", &response, true);
                }
                response
            }
            Err(e) => format!("AI error: {}", e),
        },
        None => "AI not initialized".to_string(),
    }
}

/// Ask the AI with text + images (LLaVA multimodal)
#[flutter_rust_bridge::frb]
pub async fn ask_ai_multimodal(prompt: String, images_base64: Vec<String>) -> String {
    let core = INSTANCE.read().await;
    match &core.ai {
        Some(ai) => match ai.generate_multimodal(&prompt, images_base64).await {
            Ok(response) => {
                if let Some(storage) = &core.storage {
                    let _ = storage.write().await.save_message("AI", &response, true);
                }
                response
            }
            Err(e) => format!("Multimodal AI error: {}", e),
        },
        None => "AI not initialized".to_string(),
    }
}

/// Connect to a peer by multiaddr
#[flutter_rust_bridge::frb]
pub async fn connect_to_peer(address: String) -> String {
    let core = INSTANCE.read().await;
    match &core.swarm {
        Some(swarm) => {
            let mut s = swarm.write().await;
            match s.dial(&address).await {
                Ok(_) => format!("connecting to {}", address),
                Err(e) => format!("connect error: {}", e),
            }
        }
        None => "not initialized".to_string(),
    }
}

/// Check if AI server is healthy
#[flutter_rust_bridge::frb]
pub async fn check_ai_health() -> bool {
    let core = INSTANCE.read().await;
    match &core.ai {
        Some(ai) => ai.health().await,
        None => false,
    }
}

/// Get recent messages from local storage
#[flutter_rust_bridge::frb]
pub async fn get_message_history(limit: i64) -> Vec<MessageEntry> {
    let core = INSTANCE.read().await;
    match &core.storage {
        Some(storage) => {
            let db = storage.read().await;
            match db.get_recent_messages(limit) {
                Ok(msgs) => msgs.into_iter().map(|m| MessageEntry {
                    id: m.id,
                    sender: m.sender,
                    content: m.content,
                    is_ai: m.is_ai,
                    timestamp: m.timestamp,
                }).collect(),
                Err(_) => vec![],
            }
        }
        None => vec![],
    }
}

/// Flutter-accessible message entry
#[flutter_rust_bridge::frb]
pub struct MessageEntry {
    pub id: i64,
    pub sender: String,
    pub content: String,
    pub is_ai: bool,
    pub timestamp: String,
}

// ── Minima / DADA Point Reward API ──────────────────────────────────────────

#[flutter_rust_bridge::frb]
pub async fn init_minima(minima_url: String) -> String {
    let mut core = INSTANCE.write().await;
    let minima = MinimaService::new(&minima_url);
    let reward = RewardService::new(minima.clone());

    let healthy = reward.health().await;
    core.reward = Some(reward);

    if healthy {
        match minima.get_address().await {
            Ok(addr) => format!("Minima connected: {}", addr),
            Err(e) => format!("Minima reachable but address error: {}", e),
        }
    } else {
        "Minima node unreachable — rewards will be queued".to_string()
    }
}

#[flutter_rust_bridge::frb]
pub async fn get_minima_address() -> String {
    let core = INSTANCE.read().await;
    match &core.reward {
        Some(r) => match r.get_minima_address().await {
            Ok(addr) => addr,
            Err(e) => format!("error: {}", e),
        },
        None => "Minima not initialized".to_string(),
    }
}

#[flutter_rust_bridge::frb]
pub struct DADABalance {
    pub balance: u64,
    pub address: String,
}

#[flutter_rust_bridge::frb]
pub async fn get_dada_balance() -> DADABalance {
    let core = INSTANCE.read().await;
    match &core.reward {
        Some(r) => {
            let addr = r.get_minima_address().await.unwrap_or_default();
            let bal = r.get_dada_balance().await.unwrap_or(0);
            DADABalance {
                balance: bal,
                address: addr,
            }
        }
        None => DADABalance {
            balance: 0,
            address: String::new(),
        },
    }
}

#[flutter_rust_bridge::frb]
pub struct RewardResult {
    pub points_earned: u32,
    pub tx_id: String,
    pub action: String,
    pub success: bool,
    pub error: String,
}

#[flutter_rust_bridge::frb]
pub async fn reward_for_watch(
    user_address: String,
    video_cid: String,
    seconds: u32,
) -> RewardResult {
    let core = INSTANCE.read().await;
    match &core.reward {
        Some(r) => {
            match r
                .issue_reward(&user_address, &ActionType::WatchVideo, seconds, &video_cid)
                .await
            {
                Ok(result) => RewardResult {
                    points_earned: result.points_earned,
                    tx_id: result.tx_id,
                    action: result.action,
                    success: true,
                    error: String::new(),
                },
                Err(e) => RewardResult {
                    points_earned: 0,
                    tx_id: String::new(),
                    action: "watch".to_string(),
                    success: false,
                    error: e,
                },
            }
        }
        None => RewardResult {
            points_earned: 0,
            tx_id: String::new(),
            action: "watch".to_string(),
            success: false,
            error: "Minima not initialized".to_string(),
        },
    }
}

#[flutter_rust_bridge::frb]
pub async fn reward_for_ai_chat(
    user_address: String,
    chat_id: String,
    seconds: u32,
) -> RewardResult {
    let core = INSTANCE.read().await;
    match &core.reward {
        Some(r) => {
            match r
                .issue_reward(&user_address, &ActionType::AIChat, seconds, &chat_id)
                .await
            {
                Ok(result) => RewardResult {
                    points_earned: result.points_earned,
                    tx_id: result.tx_id,
                    action: result.action,
                    success: true,
                    error: String::new(),
                },
                Err(e) => RewardResult {
                    points_earned: 0,
                    tx_id: String::new(),
                    action: "ai".to_string(),
                    success: false,
                    error: e,
                },
            }
        }
        None => RewardResult {
            points_earned: 0,
            tx_id: String::new(),
            action: "ai".to_string(),
            success: false,
            error: "Minima not initialized".to_string(),
        },
    }
}

#[flutter_rust_bridge::frb]
pub async fn reward_for_relay(
    user_address: String,
    relay_id: String,
    seconds: u32,
) -> RewardResult {
    let core = INSTANCE.read().await;
    match &core.reward {
        Some(r) => {
            match r
                .issue_reward(&user_address, &ActionType::P2PRelay, seconds, &relay_id)
                .await
            {
                Ok(result) => RewardResult {
                    points_earned: result.points_earned,
                    tx_id: result.tx_id,
                    action: result.action,
                    success: true,
                    error: String::new(),
                },
                Err(e) => RewardResult {
                    points_earned: 0,
                    tx_id: String::new(),
                    action: "relay".to_string(),
                    success: false,
                    error: e,
                },
            }
        }
        None => RewardResult {
            points_earned: 0,
            tx_id: String::new(),
            action: "relay".to_string(),
            success: false,
            error: "Minima not initialized".to_string(),
        },
    }
}

#[flutter_rust_bridge::frb]
pub async fn check_minima_health() -> bool {
    let core = INSTANCE.read().await;
    match &core.reward {
        Some(r) => r.health().await,
        None => false,
    }
}
