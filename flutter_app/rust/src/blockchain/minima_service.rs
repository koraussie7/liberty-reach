use reqwest::Client;
use serde_json::Value;

const DADAPOINT_TOKENID: &str = "0x16FA1259ABD7884382D6D1C42608843047A5BD98E80BBDC375086B803C0404E5";

#[derive(Clone)]
pub struct MinimaService {
    client: Client,
    rpc_url: String,
}

#[derive(Debug, Clone)]
pub struct MinimaBalance {
    pub address: String,
    pub total_coins: u64,
    pub dada_point_balance: u64,
}

impl MinimaService {
    pub fn new(rpc_url: &str) -> Self {
        let client = Client::builder()
            .danger_accept_invalid_certs(true)
            .build()
            .expect("Failed to build Minima HTTP client");
        Self {
            client,
            rpc_url: rpc_url.trim_end_matches('/').to_string(),
        }
    }

    pub async fn get_address(&self) -> Result<String, String> {
        let resp = self.send_cmd("newaddress").await?;
        let addr = resp["response"]["address"]
            .as_str()
            .map(String::from)
            .ok_or_else(|| "No address in Minima response".to_string())?;
        Ok(addr)
    }

    pub async fn get_balance(&self) -> Result<MinimaBalance, String> {
        let resp = self.send_cmd("balance").await?;
        let entries = resp["response"].as_array().cloned().unwrap_or_default();

        let total_coins = entries
            .iter()
            .find(|e| e["tokenid"] == "0x00")
            .and_then(|e| e["confirmed"].as_str())
            .and_then(|s| s.split('.').next().and_then(|s| s.parse().ok()))
            .unwrap_or(0);

        let dada_point_balance = entries
            .iter()
            .find(|e| {
                e.get("token")
                    .and_then(|t| t.get("name"))
                    .and_then(|n| n.as_str())
                    == Some("DADAPOINT")
                    || e["tokenid"].as_str() == Some(DADAPOINT_TOKENID)
            })
            .and_then(|e| e["confirmed"].as_str())
            .and_then(|s| s.parse().ok())
            .unwrap_or(0);

        Ok(MinimaBalance {
            address: String::new(),
            total_coins,
            dada_point_balance,
        })
    }

    pub async fn send_reward(
        &self,
        to_address: &str,
        amount: u64,
        _memo: &str,
    ) -> Result<String, String> {
        let cmd = format!(
            "send address:{} amount:{} tokenid:{}",
            to_address, amount, DADAPOINT_TOKENID
        );
        let resp = self.send_cmd(&cmd).await?;

        if resp["status"].as_bool().unwrap_or(false) {
            Ok(resp["response"]["txpowid"]
                .as_str()
                .unwrap_or("unknown")
                .to_string())
        } else {
            Err(resp["error"]
                .as_str()
                .unwrap_or("Minima send failed")
                .to_string())
        }
    }

    pub async fn health(&self) -> bool {
        self.send_cmd("status")
            .await
            .map(|r| r["status"].as_bool().unwrap_or(false))
            .unwrap_or(false)
    }

    async fn send_cmd(&self, cmd: &str) -> Result<Value, String> {
        let resp = self
            .client
            .post(&self.rpc_url)
            .header("Content-Type", "text/plain")
            .body(cmd.to_string())
            .send()
            .await
            .map_err(|e| format!("Minima RPC error: {}", e))?;
        resp.json()
            .await
            .map_err(|e| format!("Minima parse error: {}", e))
    }
}
