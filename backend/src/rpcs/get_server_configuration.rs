use crate::db_connection::PgPooledConnection;
use crate::models::default_server_configuration;
use crate::schema::server_configurations::dsl::*;
use diesel::*;
use tonic::{Code, Response, Status};

use crate::conversions::ToProtoServerConfiguration;
use crate::{models, protos};

pub fn get_server_configuration(
    conn: &PgPooledConnection,
) -> Result<Response<protos::ServerConfiguration>, Status> {
    let server_configuration = server_configurations
        .filter(active.eq(true))
        .first::<models::ServerConfiguration>(conn);
    match server_configuration {
        Ok(server_configuration) => {
            let result = server_configuration.to_proto();
            println!("GetServerConfiguration called, returning {:?}", result);
            Ok(Response::new(result))
        }
        Err(diesel::NotFound) => {
            let result = match insert_into(server_configurations)
                .values(default_server_configuration())
                .get_result::<models::ServerConfiguration>(conn) {
                Ok(server_configuration) => server_configuration.to_proto(),
                Err(e) => {
                    println!("Error inserting default server configuration: {:?}", e);
                    return Err(Status::new(Code::Internal, "error_inserting_default_server_configuration"));
                }
            };
            println!(
                "GetServerConfiguration called, generated new one: {:?}",
                result
            );
            Ok(Response::new(result))
        }
        Err(e) => {
            println!("GetServerConfiguration error: {:?}", e);
            Err(Status::new(Code::Unauthenticated, "data_error"))
        }
    }
}