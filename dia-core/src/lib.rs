//! # dia-core
//!
//! Core library for dia - a cross-platform backend framework for Zig.
//! 
//! This crate provides the fundamental building blocks for creating web applications
//! that can be consumed by Zig through FFI interfaces.

pub mod application;
pub mod request;
pub mod response;
pub mod controller;
pub mod middleware;
pub mod ffi;

// Re-export main types for easier access
pub use application::Application;
pub use request::Request;
pub use response::Response;
pub use controller::{Controller, BasicController, Route};
pub use middleware::Middleware;

// Re-export macros from dia-macros
pub use dia_macros::*;

use std::ffi::CString;
use std::os::raw::c_char;

/// Initialize the dia framework
/// This should be called before using any other dia functions
#[unsafe(no_mangle)]
pub extern "C" fn dia_init() -> i32 {
    env_logger::init();
    log::info!("dia framework initialized");
    0
}

/// Get the version of the dia framework
#[unsafe(no_mangle)]
pub extern "C" fn dia_version() -> *const c_char {
    let version = CString::new(env!("CARGO_PKG_VERSION")).unwrap();
    version.into_raw()
}

/// Free a C string returned by dia functions
#[unsafe(no_mangle)]
pub extern "C" fn dia_free_string(s: *mut c_char) {
    if !s.is_null() {
        unsafe {
            drop(CString::from_raw(s));
        }
    }
}