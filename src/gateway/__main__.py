# src/gateway/__main__.py
import uvicorn
from .router import app

def main():
    uvicorn.run(app, host="0.0.0.0", port=8080)

if __name__ == "__main__":
    main()
