open Base

open Std

module Type = struct 
    type t =
        | Prim of string
        | Fn of t * t
end

module Field = struct 
    type t = 
        { name : string
        ; ty   : Type.t
        }
end

module Exp = struct
    type prim = 
        | PInt of int

    type alter =
        { con : string
        ; arg : string
        ; exp : t
        }

    and t =
        | App of t * t
        | Ref of string
        | Prim of prim
        | Lam of string list * t 
        | If of t * t * t
        | Case of t * alter list
        | Let of string * Type.t option * t
        | Seq of t * t
end

module Comb = struct 
    type t =
        { name : string
        ; args : Field.t list
        ; ty   : Type.t
        ; exp  : Exp.t
        }
end

module Record = struct 
    type t =
        { name : string 
        ; fs   : Field.t list
        }
end

module Variant = struct
    type t = 
        { name : string
        ; vars : Record.t list
        }
end

module Data = struct
    type t =
        | Var of Variant.t
        | Rec of Record.t
end

module Toplevel = struct 
    type t = (Data.t, Comb.t) Either.t
end
 
module Module = struct
    type t =
        { file : File.t
        ; tls  : Toplevel.t list
        }
end
