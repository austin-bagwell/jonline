use std::env;

use awscreds::Credentials;
use awsregion::Region;
use s3::error::S3Error;
use s3::Bucket;

pub async fn get_and_test_bucket() -> Result<Bucket, S3Error> {
    let minio_endpoint = env::var("MINIO_ENDPOINT").map_err(
      |_| {S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar("MINIO_ENDPOINT".to_string(), "".to_string()))})?;
    let minio_region = env::var("MINIO_REGION").map_err(
      |_| {S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar("MINIO_REGION".to_string(), "".to_string()))})?;
    let minio_bucket = env::var("MINIO_BUCKET").map_err(
      |_| {S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar("MINIO_BUCKET".to_string(), "".to_string()))})?;
    let minio_access_key = env::var("MINIO_ACCESS_KEY").map_err(
      |_| {S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar("MINIO_ACCESS_KEY".to_string(), "".to_string()))})?;
    let minio_secret_key = env::var("MINIO_SECRET_KEY").map_err(
      |_| {S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar("MINIO_SECRET_KEY".to_string(), "".to_string()))})?;
    // let bucket = Bucket::new(
    //     "rust-s3-test",
    //     "eu-central-1".parse()?,

    //     // Credentials are collected from environment, config, profile or instance metadata
    //     Credentials::default().map_err(|e| S3Error::Credentials(e))?,
    // )?;
    let bucket = Bucket::new(
        &minio_bucket,
        Region::Custom {
            region: minio_region,
            endpoint: minio_endpoint,
        },
        Credentials {
            access_key: Some(minio_access_key),
            secret_key: Some(minio_secret_key),
            security_token: None,
            expiration: None,
            session_token: None,
        },
    )?
    .with_path_style();

    let s3_path = "test.file";
    let test = b"I'm going to S3!";

    let response_data = bucket.put_object(s3_path, test).await?;
    assert_eq!(response_data.status_code(), 200);

    let response_data = bucket.get_object(s3_path).await?;
    assert_eq!(response_data.status_code(), 200);
    assert_eq!(test, response_data.as_slice());

    let response_data = bucket
        .get_object_range(s3_path, 100, Some(1000))
        .await
        .unwrap();
    assert_eq!(response_data.status_code(), 206);
    let (head_object_result, code) = bucket.head_object(s3_path).await?;
    assert_eq!(code, 200);
    assert_eq!(
        head_object_result.content_type.unwrap_or_default(),
        "application/octet-stream".to_owned()
    );

    let response_data = bucket.delete_object(s3_path).await?;
    assert_eq!(response_data.status_code(), 204);
    Ok(bucket)
}
