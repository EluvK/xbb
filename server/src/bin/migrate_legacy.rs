use std::env;
use std::path::Path;
use anyhow::{Context, Result};
use server::migrate::migrate_legacy_db;
use server::storage::{create_raw_pool, create_sqlite_pool};

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let args: Vec<String> = env::args().collect();
    let mut source_path = None;
    let mut target_path = None;

    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--source" | "-s" => {
                if i + 1 < args.len() {
                    source_path = Some(args[i + 1].clone());
                    i += 1;
                }
            }
            "--target" | "-t" => {
                if i + 1 < args.len() {
                    target_path = Some(args[i + 1].clone());
                    i += 1;
                }
            }
            other if !other.starts_with('-') => {
                if source_path.is_none() {
                    source_path = Some(other.to_string());
                } else if target_path.is_none() {
                    target_path = Some(other.to_string());
                }
            }
            _ => {}
        }
        i += 1;
    }

    let (src, tgt) = match (source_path, target_path) {
        (Some(s), Some(t)) => (s, t),
        _ => {
            eprintln!("Usage: migrate_legacy --source <LEGACY_DB> --target <NEW_DB>");
            eprintln!("   or: migrate_legacy <LEGACY_DB> <NEW_DB>");
            std::process::exit(1);
        }
    };

    if !Path::new(&src).exists() {
        anyhow::bail!("Source database file not found: {}", src);
    }

    println!("Starting migration from {src} to {tgt}...");
    let source_pool = create_raw_pool(&format!("sqlite://{}", src))
        .await
        .context("Failed to connect to source legacy database")?;
    let target_pool = create_sqlite_pool(&format!("sqlite://{}", tgt))
        .await
        .context("Failed to connect to target database")?;

    let report = migrate_legacy_db(&source_pool, &target_pool).await?;

    println!("Migration completed successfully!");
    println!("  Collections migrated: {:?}", report.collections);
    println!("  Entities migrated:    {}", report.entities_count);
    println!("  ChangeLogs generated: {}", report.change_logs_count);
    println!("  ACL records migrated: {}", report.acls_count);

    Ok(())
}
