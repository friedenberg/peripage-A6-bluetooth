use anyhow::{Context, Result};
use bluer::rfcomm::{Socket, SocketAddr, Stream};
use bluer::Address;
use std::time::Duration;
use tokio::io::AsyncWriteExt;

const RFCOMM_CHANNEL: u8 = 1;
const MAX_CHUNK_ROWS: u16 = 255;
const ROW_DELAY: Duration = Duration::from_millis(10);

pub const A6_ROW_WIDTH: u32 = 384;
pub const A6P_ROW_WIDTH: u32 = 576;

pub const A6_ROW_BYTES: u8 = 48;
pub const A6P_ROW_BYTES: u8 = 72;

pub async fn connect(mac: Address) -> Result<Stream> {
    let socket = Socket::new()?;
    let addr = SocketAddr::new(mac, RFCOMM_CHANNEL);
    let stream = socket
        .connect(addr)
        .await
        .with_context(|| format!("failed to connect to {mac} on channel {RFCOMM_CHANNEL}"))?;
    Ok(stream)
}

pub async fn reset(stream: &mut Stream) -> Result<()> {
    let mut cmd = vec![0x10, 0xFF, 0xFE, 0x01];
    cmd.extend_from_slice(&[0u8; 12]);
    stream.write_all(&cmd).await?;
    Ok(())
}

pub async fn set_concentration(stream: &mut Stream, level: u8) -> Result<()> {
    let cmd = [0x10, 0xFF, 0x10, 0x00, level];
    stream.write_all(&cmd).await?;
    Ok(())
}

pub async fn print_image(
    stream: &mut Stream,
    data: &[u8],
    row_bytes: u8,
    height: u16,
) -> Result<()> {
    let rb = row_bytes as usize;
    let mut rows_sent: u16 = 0;

    while rows_sent < height {
        let remaining = height - rows_sent;
        let chunk_height = remaining.min(MAX_CHUNK_ROWS);

        // Print preamble: 1d 76 30 00 [row_bytes] 00 [chunk_height] 00
        let preamble = [
            0x1D,
            0x76,
            0x30,
            0x00,
            row_bytes,
            0x00,
            chunk_height as u8,
            0x00,
        ];
        stream.write_all(&preamble).await?;

        for row in 0..chunk_height {
            let offset = (rows_sent + row) as usize * rb;
            let row_data = &data[offset..offset + rb];
            stream.write_all(row_data).await?;
            tokio::time::sleep(ROW_DELAY).await;
        }

        rows_sent += chunk_height;
    }

    Ok(())
}

pub async fn feed_and_end(stream: &mut Stream) -> Result<()> {
    // Paper feed: 1b 4a 40
    stream.write_all(&[0x1B, 0x4A, 0x40]).await?;
    // End: 10 ff fe 45
    stream.write_all(&[0x10, 0xFF, 0xFE, 0x45]).await?;
    Ok(())
}
