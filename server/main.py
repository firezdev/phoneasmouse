import pyautogui
from fastapi import FastAPI, WebSocket
from pyautogui import mouseDown as mouse_down
from pyautogui import mouseUp as mouse_up
from pyautogui import moveTo as move_to
from pyautogui import scroll
from uvicorn import run

app = FastAPI()
pyautogui.PAUSE = 0
pyautogui.FAILSAFE = False


@app.websocket("/ws")
async def websocket(websocket: WebSocket):
    await websocket.accept()
    move_to(1920 / 2, 1080 / 2)

    while True:
        data: dict = await websocket.receive_json()
        print(data)
        if data["action"] == "left":
            (mouse_down if data["state"] == "down" else mouse_up)(button="left")
        if data["action"] == "right":
            (mouse_down if data["state"] == "down" else mouse_up)(button="right")
        if data["action"] == "middle":
            (mouse_down if data["state"] == "down" else mouse_up)(button="middle")
        if data["action"] == "move":
            move_to(data["z"] * 1920, data["x"] * 1080)
        if data["action"] == "scroll":
            scroll(-1 if data["state"] == "down" else 1)


run(app, host="192.168.1.10")
