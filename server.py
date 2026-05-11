import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os
import asyncio
from typing import Dict

load_dotenv()

app = FastAPI(title='DADA-AI Server', version='0.1.0')

# CORS 설정 (Flutter, 웹, 모바일 모두 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=['*'],           # 배포 시에는 실제 도메인으로 제한 권장
    allow_credentials=True,
    allow_methods=['*'],
    allow_headers=['*'],
)

# 간단한 인메모리 연결 관리 (WebSocket)
active_connections: Dict[str, WebSocket] = {}

@app.get('/')
async def root():
    return {
        'status': 'ok',
        'message': 'DADA-AI Server is running',
        'version': '0.1.0'
    }

@app.get('/health')
async def health():
    return {'status': 'healthy'}

# WebSocket - 실시간 채팅용
@app.websocket('/ws/{client_id}')
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await websocket.accept()
    active_connections[client_id] = websocket
    try:
        while True:
            data = await websocket.receive_text()
            # Echo + Multi-Agent 처리 (나중에 Rust Bridge로 연결)
            await websocket.send_text(f'[Server] {data}')
    except WebSocketDisconnect:
        active_connections.pop(client_id, None)

# AI 채팅 엔드포인트
@app.post('/ai/chat')
async def ai_chat(request: dict):
    return {'response': 'AI 응답 준비중...', 'agent': 'Hermes'}

if __name__ == '__main__':
    port = int(os.getenv('SERVER_PORT', 8000))
    print(f'=== DADA-AI Server starting on port {port} ===')
    uvicorn.run(
        'server:app',
        host='0.0.0.0',
        port=port,
        reload=True,
        log_level='info'
    )
