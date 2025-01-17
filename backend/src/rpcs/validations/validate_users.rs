use super::OperationType;
use super::{validate_email, validate_phone, validate_username};
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::protos::*;

pub fn validate_user(user: &User) -> Result<(), Status> {
    validate_username(&user.username)?;
    match user.email.to_owned() {
        Some(e) => validate_email(&e.value)?,
        None => {}
    }
    match user.email.to_owned() {
        Some(e) => validate_phone(&e.value)?,
        None => {}
    }
    user.avatar_media_id.to_db_opt_id_or_err("avatar_media_id")?;
    match user.visibility.to_proto_visibility().unwrap() {
        Visibility::Unknown => return Err(Status::new(Code::NotFound, "invalid_visibility")),
        _ => (),
    };
    match user
        .default_follow_moderation
        .to_proto_moderation()
        .unwrap()
    {
        Moderation::Pending | Moderation::Unmoderated => (),
        _ => {
            return Err(Status::new(
                Code::NotFound,
                "invalid_default_follow_moderation",
            ))
        }
    };
    for permission in user.permissions.to_proto_permissions() {
        match permission {
            Permission::Unknown => {
                return Err(Status::new(
                    Code::NotFound,
                    format!("invalid_permission_{}", permission.as_str_name()),
                ))
            }
            _ => (),
        };
    }
    Ok(())
}

pub fn validate_follow(follow: &Follow, validation_type: OperationType) -> Result<(), Status> {
    follow.user_id.to_db_id_or_err("user_id")?;
    follow.target_user_id.to_db_id_or_err("target_user_id")?;
    if follow.user_id == follow.target_user_id {
        return Err(Status::new(
            Code::InvalidArgument,
            "user_cannot_follow_themselves",
        ));
    }
    match validation_type {
        OperationType::Update => {
            match follow.target_user_moderation.to_proto_moderation().unwrap() {
                Moderation::Approved | Moderation::Rejected => {}
                _ => return Err(Status::new(Code::Internal, "invalid_target_user_moderation")),
            };
        }
        _ => ()
    }
    Ok(())
}
