from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    db_host: str = "localhost"
    db_port: int = 1433
    db_name: str = "SommelierVirtual"
    db_user: str = "api_sommelier"
    db_password: str = ""
    ollama_url: str = "http://localhost:11434"
    ollama_chat_model: str = "llama3.2"


settings = Settings()
