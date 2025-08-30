//! Controller module for dia framework
//! 
//! Provides the Controller trait and routing functionality.

use crate::{Request, Response};
use actix_web::{web, HttpRequest, HttpResponse, Result as ActixResult};
use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;

/// Type alias for handler functions
pub type HandlerFn = Arc<dyn Fn(Request, Response) -> Pin<Box<dyn Future<Output = Response> + Send>> + Send + Sync>;

/// Trait for implementing controllers
pub trait Controller: Send + Sync {
    /// Register routes for this controller
    fn register_routes(&self, config: &mut web::ServiceConfig);
    
    /// Get the base path for this controller (optional)
    fn base_path(&self) -> Option<&str> {
        None
    }
}

/// Route definition struct
#[derive(Clone)]
pub struct Route {
    /// HTTP method (GET, POST, etc.)
    pub method: String,
    /// URL path pattern
    pub path: String,
    /// Handler function
    pub handler: HandlerFn,
}

impl Route {
    /// Create a new GET route
    pub fn get<S: Into<String>>(path: S, handler: HandlerFn) -> Self {
        Self {
            method: "GET".to_string(),
            path: path.into(),
            handler,
        }
    }

    /// Create a new POST route
    pub fn post<S: Into<String>>(path: S, handler: HandlerFn) -> Self {
        Self {
            method: "POST".to_string(),
            path: path.into(),
            handler,
        }
    }

    /// Create a new PUT route
    pub fn put<S: Into<String>>(path: S, handler: HandlerFn) -> Self {
        Self {
            method: "PUT".to_string(),
            path: path.into(),
            handler,
        }
    }

    /// Create a new DELETE route
    pub fn delete<S: Into<String>>(path: S, handler: HandlerFn) -> Self {
        Self {
            method: "DELETE".to_string(),
            path: path.into(),
            handler,
        }
    }

    /// Create a new PATCH route
    pub fn patch<S: Into<String>>(path: S, handler: HandlerFn) -> Self {
        Self {
            method: "PATCH".to_string(),
            path: path.into(),
            handler,
        }
    }
}

/// Basic controller implementation that holds routes
pub struct BasicController {
    /// List of routes
    routes: Vec<Route>,
    /// Base path for all routes in this controller
    base_path: Option<String>,
}

impl BasicController {
    /// Create a new basic controller
    pub fn new() -> Self {
        Self {
            routes: Vec::new(),
            base_path: None,
        }
    }

    /// Set the base path for this controller
    pub fn base_path<S: Into<String>>(mut self, path: S) -> Self {
        self.base_path = Some(path.into());
        self
    }

    /// Add a route to this controller
    pub fn route(mut self, route: Route) -> Self {
        self.routes.push(route);
        self
    }

    /// Add a GET route
    pub fn get<F>(self, path: &str, handler: F) -> Self 
    where
        F: Fn(Request, Response) -> Pin<Box<dyn Future<Output = Response> + Send>> + Send + Sync + 'static,
    {
        self.route(Route::get(path, Arc::new(handler)))
    }

    /// Add a POST route
    pub fn post<F>(self, path: &str, handler: F) -> Self 
    where
        F: Fn(Request, Response) -> Pin<Box<dyn Future<Output = Response> + Send>> + Send + Sync + 'static,
    {
        self.route(Route::post(path, Arc::new(handler)))
    }

    /// Add a PUT route
    pub fn put<F>(self, path: &str, handler: F) -> Self 
    where
        F: Fn(Request, Response) -> Pin<Box<dyn Future<Output = Response> + Send>> + Send + Sync + 'static,
    {
        self.route(Route::put(path, Arc::new(handler)))
    }

    /// Add a DELETE route
    pub fn delete<F>(self, path: &str, handler: F) -> Self 
    where
        F: Fn(Request, Response) -> Pin<Box<dyn Future<Output = Response> + Send>> + Send + Sync + 'static,
    {
        self.route(Route::delete(path, Arc::new(handler)))
    }

    /// Add a PATCH route
    pub fn patch<F>(self, path: &str, handler: F) -> Self 
    where
        F: Fn(Request, Response) -> Pin<Box<dyn Future<Output = Response> + Send>> + Send + Sync + 'static,
    {
        self.route(Route::patch(path, Arc::new(handler)))
    }
}

impl Controller for BasicController {
    fn register_routes(&self, config: &mut web::ServiceConfig) {
        for route in &self.routes {
            let full_path = if let Some(base) = &self.base_path {
                format!("{}{}", base, route.path)
            } else {
                route.path.clone()
            };

            let handler = route.handler.clone();
            
            // Convert our handler to actix-web handler
            let actix_handler = move |req: HttpRequest| {
                let handler = handler.clone();
                async move {
                    let dia_req = Request::new(req);
                    let dia_resp = Response::new();
                    let result = handler(dia_req, dia_resp).await;
                    Ok::<HttpResponse, actix_web::Error>(result.into_http_response())
                }
            };

            match route.method.as_str() {
                "GET" => {
                    config.route(&full_path, web::get().to(actix_handler));
                }
                "POST" => {
                    config.route(&full_path, web::post().to(actix_handler));
                }
                "PUT" => {
                    config.route(&full_path, web::put().to(actix_handler));
                }
                "DELETE" => {
                    config.route(&full_path, web::delete().to(actix_handler));
                }
                "PATCH" => {
                    config.route(&full_path, web::patch().to(actix_handler));
                }
                _ => {
                    log::warn!("Unsupported HTTP method: {}", route.method);
                }
            }
        }
    }

    fn base_path(&self) -> Option<&str> {
        self.base_path.as_deref()
    }
}

impl Default for BasicController {
    fn default() -> Self {
        Self::new()
    }
}