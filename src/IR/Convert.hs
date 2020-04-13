{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}}

module IR.Convert where

import qualified Parser.AST as AST
import qualified IR.IR as IR
import qualified IR.Namespace as IR
import qualified Data.Map.Strict as M
import Data.Either
import Error.Error

import Control.Monad.Trans.Except
import Control.Monad.Trans.State

import qualified Control.Monad.State.Class as SC
import qualified Control.Monad.Error.Class as EC

data Names
  = Names IR.Id IR.Name IR.Name IR.Name

fillNamespace :: Integer -> AST.Module -> EitherError IR.Module
fillNamespace id m = Left $ -- throw error if names appear duplicate maybe
  { IR.mid = id
  , IR.mdatans = nsdata ns
  , IR.mcombns = nscomb ns
  , IR.mconsns = nscons ns
  , mdata = M.empty 
  , mcomb = M.empty
  }
  where 
    ns = execState $ getNames id $ AST.ms m

getNames :: Integer -> [Either AST.Comb AST.Data] -> Namestate ()
getNames id = traverse $ \ cd -> next >>= \ i -> getName i cd
  where
    getName i (Left c)  = insertNSComb (AST.cname c) $ IR.Name id i 0
    getName i (Right (SData d)) = (insertNSData AST.sname d $ IR.Name id i 0) 
                                    >> traverse (next >>= \ i -> getNameP i) $ svars d
    getName i (Right (PData d)) = (insertNSData AST.pname d $ IR.Name id i 0) >> getNameP i d
    getNameP i p = insertNSCons (pname p) $ IR.Name id i 0

data NS
  = NS 
  { nsi :: Integer
  , nsdata :: IR.Namespace
  , nscomb :: IR.Namespace 
  , nscons :: IR.Namespace
  }

type Namestate = State NS

next = gets nsi >>= \ i -> (modify $ \ (NS _ d c co) -> NS (i + 1) d c co) >> return $ i + 1

insertNSData s n = modify $ \ (NS i d c co) -> NS i (M.insert s n d) c co
insertNSComb s n = modify $ \ (NS i d c co) -> NS i d (M.insert s n c) co 
insertNSCons s n = modify $ \ (NS i d c co) -> NS i c (M.insert s n co)

-- CONVERSION

convertModule :: Integer -> -> IR.Unit -> AST.Module -> IR.Module -> EitherError IR.Module
convertModule id m = 
  
  Right $ IR.Module 
  { IR.mid   = id
  , IR.mdata = M.fromList $ map (\d -> (IR.dname d, d)) ds
  , IR.mcomb = M.fromList $ map (\c -> (IR.cname c, c)) cs
  }
  where 
    (cs, ds) = let (cs', ds') = partitionEithers $ AST.ms m in (map convertComb cs', map convertData ds')

-- TODO

class Convertable a b where
  convert :: a -> Env b

convertData :: AST.Data -> IR.Data
convertData _ = IR.SData $ IR.SumData (IR.Name 2 2 2) [IR.ProData (IR.Name 3 3 3) [IR.Member 0 $ IR.TPrim (IR.Name 1 1 1)]]

convertComb :: AST.Comb -> IR.Comb
convertComb _ = IR.Comb (IR.Name 2 2 2) (IR.EVar (IR.Name 4 4 4) (IR.TPrim (IR.Name 3 3 3))) 

-- MONAD STACK

data EnvState
  = EnvState
  { envUnit  :: IR.Unit
  , envMod   :: IR.Module
  }

newtype Env a
  = Env (StateT EnvState (Except Error) a)
  deriving (Functor, Applicative, Monad, SC.MonadState EnvState, EC.MonadError Error)

runEnv :: EnvState -> Env a -> Either Error a
runEnv is (Env s) = runExcept $ evalStateT s is

