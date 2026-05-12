use crate::blockchain::minima_service::MinimaService;

#[derive(Debug, Clone)]
pub enum ActionType {
    WatchVideo,
    AIChat,
    P2PRelay,
}

#[derive(Debug, Clone)]
pub struct RewardResult {
    pub points_earned: u32,
    pub tx_id: String,
    pub action: String,
}

pub struct RewardService {
    minima: MinimaService,
}

impl RewardService {
    pub fn new(minima: MinimaService) -> Self {
        Self { minima }
    }

    pub fn calculate_points(action: &ActionType, duration_seconds: u32) -> u32 {
        match action {
            ActionType::WatchVideo => (duration_seconds / 15).max(1),
            ActionType::AIChat => (duration_seconds / 30).max(1),
            ActionType::P2PRelay => (duration_seconds / 60).max(1),
        }
    }

    pub async fn issue_reward(
        &self,
        user_address: &str,
        action: &ActionType,
        duration_seconds: u32,
        action_id: &str,
    ) -> Result<RewardResult, String> {
        let points = Self::calculate_points(action, duration_seconds);
        if points == 0 {
            return Err("No points earned (duration too short)".to_string());
        }

        let memo = format!("{}:{}", Self::action_label(action), action_id);
        let tx_id = self
            .minima
            .send_reward(user_address, points as u64, &memo)
            .await?;

        Ok(RewardResult {
            points_earned: points,
            tx_id,
            action: Self::action_label(action).to_string(),
        })
    }

    fn action_label(action: &ActionType) -> &'static str {
        match action {
            ActionType::WatchVideo => "watch",
            ActionType::AIChat => "ai",
            ActionType::P2PRelay => "relay",
        }
    }

    pub async fn health(&self) -> bool {
        self.minima.health().await
    }

    pub async fn get_minima_address(&self) -> Result<String, String> {
        self.minima.get_address().await
    }

    pub async fn get_dada_balance(&self) -> Result<u64, String> {
        let bal = self.minima.get_balance().await?;
        Ok(bal.dada_point_balance)
    }
}
