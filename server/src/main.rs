use salvo::prelude::*;
use server::auth::AuthMiddleware;
use server::router::create_app_router_with_db;
use server::storage::create_sqlite_pool;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let port = std::env::var("PORT").unwrap_or_else(|_| "10101".to_string());
    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://data/sync.db".to_string());

    let _ = tokio::fs::create_dir_all("data").await;

    tracing::info!("Initializing SQLite storage pool at {db_url}...");
    let pool = create_sqlite_pool(&db_url).await?;

    let router = create_app_router_with_db(pool, AuthMiddleware::default());

    let bind_addr = format!("0.0.0.0:{port}");
    println!("Server listening on http://{bind_addr}");
    tracing::info!("Server listening on http://{bind_addr}");

    let acceptor = TcpListener::new(bind_addr).bind().await;
    Server::new(acceptor).serve(router).await;

    Ok(())
}
