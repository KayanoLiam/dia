//! # dia-macros
//!
//! Procedural macros for dia framework.
//! 
//! This crate provides convenient macros for defining routes and controllers
//! in a declarative way similar to other web frameworks.

use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, ItemFn, LitStr, punctuated::Punctuated, Expr, Token};

/// Generate a GET route handler
/// 
/// # Examples
/// 
/// ```rust
/// use dia_macros::get;
/// 
/// #[get("/users")]
/// async fn get_users() -> Response {
///     Response::new().json(json!({"users": []}))
/// }
/// ```
#[proc_macro_attribute]
pub fn get(args: TokenStream, input: TokenStream) -> TokenStream {
    route_macro("GET", args, input)
}

/// Generate a POST route handler
/// 
/// # Examples
/// 
/// ```rust
/// use dia_macros::post;
/// 
/// #[post("/users")]
/// async fn create_user() -> Response {
///     Response::new().json(json!({"message": "User created"}))
/// }
/// ```
#[proc_macro_attribute]
pub fn post(args: TokenStream, input: TokenStream) -> TokenStream {
    route_macro("POST", args, input)
}

/// Generate a PUT route handler
#[proc_macro_attribute]
pub fn put(args: TokenStream, input: TokenStream) -> TokenStream {
    route_macro("PUT", args, input)
}

/// Generate a DELETE route handler
#[proc_macro_attribute]
pub fn delete(args: TokenStream, input: TokenStream) -> TokenStream {
    route_macro("DELETE", args, input)
}

/// Generate a PATCH route handler
#[proc_macro_attribute]
pub fn patch(args: TokenStream, input: TokenStream) -> TokenStream {
    route_macro("PATCH", args, input)
}

/// Common route macro implementation
fn route_macro(method: &str, args: TokenStream, input: TokenStream) -> TokenStream {
    let input_fn = parse_macro_input!(input as ItemFn);

    // Parse the path argument
    let path = if args.is_empty() {
        return syn::Error::new_spanned(
            &input_fn,
            format!("Expected path argument for {} route", method.to_lowercase())
        )
        .to_compile_error()
        .into();
    };

    let path_str = args.to_string().trim_matches('"').to_string();

    let fn_name = &input_fn.sig.ident;
    let fn_block = &input_fn.block;
    let fn_inputs = &input_fn.sig.inputs;
    let fn_output = &input_fn.sig.output;
    let fn_vis = &input_fn.vis;
    let fn_attrs = &input_fn.attrs;

    // Generate the route registration metadata
    let route_metadata_name = quote::format_ident!("__{}_route_metadata", fn_name);
    
    let expanded = quote! {
        #(#fn_attrs)*
        #fn_vis async fn #fn_name(#fn_inputs) #fn_output #fn_block

        // Generate route metadata that can be collected later
        #[allow(non_upper_case_globals)]
        const #route_metadata_name: (&str, &str, &str) = (#method, #path_str, stringify!(#fn_name));
    };

    TokenStream::from(expanded)
}

/// Macro to generate a controller struct with routes
/// 
/// # Examples
/// 
/// ```rust
/// use dia_macros::controller;
/// 
/// #[controller("/api")]
/// struct UserController;
/// 
/// impl UserController {
///     #[get("/users")]
///     async fn get_users() -> Response {
///         Response::new().json(json!({"users": []}))
///     }
/// }
/// ```
#[proc_macro_attribute]
pub fn controller(args: TokenStream, input: TokenStream) -> TokenStream {
    let input_struct = parse_macro_input!(input as syn::ItemStruct);

    // Extract base path from arguments (simple string parsing)
    let base_path = if args.is_empty() {
        String::new()
    } else {
        args.to_string().trim_matches('"').to_string()
    };

    let struct_name = &input_struct.ident;
    let struct_vis = &input_struct.vis;
    let struct_attrs = &input_struct.attrs;

    let expanded = quote! {
        #(#struct_attrs)*
        #struct_vis struct #struct_name {
            pub base_path: String,
        }

        impl #struct_name {
            pub fn new() -> Self {
                Self {
                    base_path: #base_path.to_string(),
                }
            }
        }

        impl Default for #struct_name {
            fn default() -> Self {
                Self::new()
            }
        }
    };

    TokenStream::from(expanded)
}

/// Macro to automatically implement route registration for a controller
/// 
/// This macro should be used on an impl block to automatically register
/// all route handlers defined in the implementation.
#[proc_macro_attribute]
pub fn routes(_args: TokenStream, input: TokenStream) -> TokenStream {
    let input_impl = parse_macro_input!(input as syn::ItemImpl);
    
    // For now, just return the implementation as-is
    // In a full implementation, this would scan for route methods
    // and generate the route registration code
    
    let expanded = quote! {
        #input_impl
    };

    TokenStream::from(expanded)
}

/// Macro to generate a main function that sets up and runs the dia application
/// 
/// # Examples
/// 
/// ```rust
/// use dia_macros::main;
/// 
/// #[main]
/// async fn app() -> Result<(), Box<dyn std::error::Error>> {
///     let app = Application::new()
///         .host("0.0.0.0")
///         .port(3000);
///     
///     app.run().await?;
///     Ok(())
/// }
/// ```
#[proc_macro_attribute]
pub fn main(_args: TokenStream, input: TokenStream) -> TokenStream {
    let input_fn = parse_macro_input!(input as ItemFn);
    
    let fn_name = &input_fn.sig.ident;
    let fn_block = &input_fn.block;
    let fn_vis = &input_fn.vis;
    let fn_attrs = &input_fn.attrs;

    let expanded = quote! {
        #(#fn_attrs)*
        #[tokio::main]
        #fn_vis async fn main() -> Result<(), Box<dyn std::error::Error>> {
            dia_core::dia_init();
            #fn_name().await
        }

        async fn #fn_name() -> Result<(), Box<dyn std::error::Error>> #fn_block
    };

    TokenStream::from(expanded)
}