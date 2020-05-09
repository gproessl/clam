open Core
open Stdio
open Ast
open Std

module Config = Config
module Std = Std


let rec run (fs : File.t list) : unit = 
    ignore (List.map fs ~f:(fun s -> File.to_string s |> printf "%s\n") : unit list);
    printf "%s\n" (Config.to_string ());
    try pipe fs with | e -> Error.handle e;

and pipe (fs : File.t list) : unit =
    let ms : Types.Module.t list = parse_mods fs in 
    ignore ((List.map ~f:(fun m -> Types.Module.to_string m |> Stdio.printf "%s\n") ms) : unit list);
    let L = Converter.Make(struct let i = 10 end) in c.convert () 


and parse_mods (fs : File.t list) : Types.Module.t list =
    List.map fs ~f:(fun fi -> parse fi)