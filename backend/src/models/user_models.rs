use std::time::SystemTime;

use tonic::{Code, Status};
use diesel::*;

use crate::db_connection::PgPooledConnection;
use crate::schema::{users, follows};

pub fn get_user(user_id: i64, conn: &mut PgPooledConnection,) -> Result<User, Status> {
    users::table
        .select(users::all_columns)
        .filter(users::id.eq(user_id))
        .first::<User>(conn)
        .map_err(|_| Status::new(Code::NotFound, "user_not_found"))
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct User {
    pub id: i64,
    pub username: String,
    pub password_salted_hash: String,
    pub real_name: String,
    pub email: Option<serde_json::Value>,
    pub phone: Option<serde_json::Value>,
    /// A serialized (by name) list of [crate::protos::Permission]s.
    pub permissions: serde_json::Value,
    pub avatar_media_id: Option<i64>,
    pub bio: String,
    pub visibility: String,
    pub moderation: String,
    pub default_follow_moderation: String,
    pub follower_count: i32,
    pub following_count: i32,
    pub group_count: i32,
    pub post_count: i32,
    pub event_count: i32,
    pub response_count: i32,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Follow {
    pub id: i64,
    pub user_id: i64,
    pub target_user_id: i64,
    pub target_user_moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = follows)]
pub struct NewFollow {
    pub user_id: i64,
    pub target_user_id: i64,
    pub target_user_moderation: String,
}
