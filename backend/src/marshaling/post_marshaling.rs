use std::mem::transmute;

use diesel::*;
use itertools::Itertools;
use tonic::Code;
use tonic::Status;

use super::{ToI32Moderation, ToI32Visibility, ToLink, ToProtoId, ToProtoTime};
use crate::db_connection::{PgPooledConnection};
use crate::models;
use crate::protos::*;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::{group_posts, groups, posts};

pub trait ToProtoPost {
    fn to_proto(&self, username: Option<String>) -> Post;
    fn to_group_proto(
        &self,
        username: Option<String>,
        group_post: Option<&models::GroupPost>,
    ) -> Post;
    fn proto_author(&self, username: Option<String>) -> Option<Author>;
}

impl ToProtoPost for models::Post {
    fn to_proto(&self, username: Option<String>) -> Post {
        self.to_group_proto(username, None)
    }
    fn to_group_proto(
        &self,
        username: Option<String>,
        group_post: Option<&models::GroupPost>,
    ) -> Post {
        Post {
            id: self.id.to_proto_id(),
            reply_to_post_id: self.parent_post_id.map(|i| i.to_proto_id()),
            author: self.proto_author(username),

            title: self.title.to_owned(),
            link: self.link.to_link(),
            content: self.content.to_owned(),

            response_count: self.response_count,
            reply_count: self.reply_count,
            group_count: self.group_count,
            current_group_post: group_post.map(|gp| gp.to_proto()),
            media: self.media
                .iter()
                .map(|v| v.to_proto_id())
                .collect_vec(),
                media_generated: self.media_generated,
                embed_link: self.embed_link,
                shareable: self.shareable,

                context: self.context.to_i32_post_context(),
                visibility: self.visibility.to_i32_visibility(),
                moderation: self.moderation.to_i32_moderation(),

                replies: vec![],  //TODO update this

            created_at: Some(self.created_at.to_proto()),
            updated_at: self.updated_at.map(|t| t.to_proto()),
            published_at: self.published_at.map(|t| t.to_proto()),
            last_activity_at: Some(self.last_activity_at.to_proto()),
        }
    }
    fn proto_author(&self, username: Option<String>) -> Option<Author> {
        self.user_id.map(|user_id| Author {
            user_id: user_id.to_proto_id(),
            username: username,
        })
    }
}

pub trait ToProtoGroupPost {
    fn to_proto(&self) -> GroupPost;
    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status>;
}
impl ToProtoGroupPost for models::GroupPost {
    fn to_proto(&self) -> GroupPost {
        return GroupPost {
            group_id: self.group_id.to_proto_id().to_string(),
            post_id: self.post_id.to_proto_id().to_string(),
            user_id: self.user_id.to_proto_id().to_string(),
            group_moderation: self.group_moderation.to_i32_moderation(),
            created_at: Some(self.created_at.to_proto()),
            // updated_at: self.updated_at.map(|t| t.to_proto()),
        };
    }

    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status> {
        let post_count = group_posts::table
            .count()
            .filter(group_posts::group_id.eq(self.group_id))
            .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;
        diesel::update(groups::table)
            .filter(groups::id.eq(self.group_id))
            .set(groups::post_count.eq(post_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_group_post_count"))?;

        let group_count = group_posts::table
            .count()
            .filter(group_posts::post_id.eq(self.post_id))
            .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;
        diesel::update(posts::table)
            .filter(posts::id.eq(self.post_id))
            .set(posts::group_count.eq(group_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_post_group_count"))?;

        Ok(())
    }
}

pub const ALL_POST_CONTEXTS: [PostContext; 4] = [PostContext::Post, PostContext::Reply, PostContext::Event, PostContext::EventInstance];

pub trait ToProtoPostContext {
    fn to_proto_post_context(&self) -> Option<PostContext>;
}
impl ToProtoPostContext for String {
    fn to_proto_post_context(&self) -> Option<PostContext> {
        for post_context in ALL_POST_CONTEXTS {
            if post_context.as_str_name().eq_ignore_ascii_case(self) {
                return Some(post_context);
            }
        }
        return None;
    }
}
impl ToProtoPostContext for i32 {
    fn to_proto_post_context(&self) -> Option<PostContext> {
        Some(unsafe { transmute::<i32, PostContext>(*self) })
    }
}

pub trait ToI32PostContext {
    fn to_i32_post_context(&self) -> i32;
}
impl ToI32PostContext for String {
    fn to_i32_post_context(&self) -> i32 {
        self.to_proto_post_context().unwrap() as i32
    }
}
