//! Application module for dia framework
//! 
//! Provides the main Application struct for setting up and running web servers.

use actix_web::{web, App, HttpServer, middleware::Logger};
use std::sync::Arc;
use std::collections::HashMap;
use anyhow::Result;
use log::info;

use crate::controller::Controller;
use crate::middleware::Middleware;

/// Main application struct that holds the web server configuration
pub struct Application {
    /// The host address to bind to
    host: String,
    /// The port to bind to
    port: u16,
    /// Registered controllers
    controllers: Vec<Arc<dyn Controller>>,
    /// Registered middlewares
    middlewares: Vec<Box<dyn Middleware>>,
    /// Application state
    state: HashMap<String, String>,
}

impl Application {
    /// Create a new Application instance
    /// 
    /// # Examples
    /// 
    /// ```rust
    /// use dia_core::Application;
    /// 
    /// let app = Application::new();
    /// ```
    pub fn new() -> Self {
        Self {
            host: "127.0.0.1".to_string(),
            port: 8080,
            controllers: Vec::new(),
            middlewares: Vec::new(),
            state: HashMap::new(),
        }
    }

    /// Set the host address for the server
    pub fn host<S: Into<String>>(mut self, host: S) -> Self {
        self.host = host.into();
        self
    }

    /// Set the port for the server
    pub fn port(mut self, port: u16) -> Self {
        self.port = port;
        self
    }

    /// Add a controller to the application
    pub fn controller<C: Controller + 'static>(mut self, controller: C) -> Self {
        self.controllers.push(Arc::new(controller));
        self
    }

    /// Add middleware to the application
    pub fn middleware<M: Middleware + 'static>(mut self, middleware: M) -> Self {
        self.middlewares.push(Box::new(middleware));
        self
    }

    /// Set application state
    pub fn state<K: Into<String>, V: Into<String>>(mut self, key: K, value: V) -> Self {
        self.state.insert(key.into(), value.into());
        self
    }

    /// Run the application server
    /// 
    /// This method starts the HTTP server and blocks until the server is stopped.
    /// 
    /// # Examples
    /// 
    /// ```rust
    /// use dia_core::Application;
    /// 
    /// #[tokio::main]
    /// async fn main() -> Result<(), Box<dyn std::error::Error>> {
    ///     let app = Application::new()
    ///         .host("0.0.0.0")
    ///         .port(3000);
    ///     
    ///     app.run().await?;
    ///     Ok(())
    /// }
    /// ```
    pub async fn run(self) -> Result<()> {
        let bind_address = format!("{}:{}", self.host, self.port);
        info!("Starting dia server on {}", bind_address);

        let state = Arc::new(self.state);
        let controllers = self.controllers;

        HttpServer::new(move || {
            let mut app = App::new()
                .app_data(web::Data::new(state.clone()))
                .wrap(Logger::default());

            // Apply middlewares
            // TODO: Apply custom middlewares here

            // Register controllers
            for controller in &controllers {
                app = app.configure(|cfg| {
                    controller.register_routes(cfg);
                });
            }

            app
        })
        .bind(&bind_address)?
        .run()
        .await?;

        Ok(())
    }
}

impl Default for Application {
    fn default() -> Self {
        Self::new()
    }
}