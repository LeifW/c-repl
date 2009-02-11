#! /usr/bin/env runhaskell

This setup file ought to be pretty simple, but we have one extra dependency:
our "child" executable, a helper program that's written in C.  So we have to
patch in a compile and install step for the child program.

> import Distribution.Simple
> import Distribution.PackageDescription
> import Distribution.Simple.LocalBuildInfo
> import Distribution.Simple.Setup
> import Distribution.Simple.Program
> import Distribution.Simple.Utils
> import Distribution.Verbosity
> import System.FilePath ((</>))

Since we depend on gcc anyway at runtime, I suppose it's harmless to pull in
gcc here...

> creplChildName :: String
> creplChildName = "c-repl-child"

> creplChildPath :: LocalBuildInfo -> FilePath
> creplChildPath buildinfo = buildDir buildinfo </> creplChildName

> creplChildBuild :: Args -> BuildFlags -> PackageDescription
>                 -> LocalBuildInfo -> IO ()
> creplChildBuild args flags desc buildinfo = do
>   rawSystemProgramConf (buildVerbose flags) gccProgram (defaultProgramConfiguration)
>       ["child.c", "-o", creplChildPath buildinfo, "-ldl"]

> creplChildCopy :: Args -> CopyFlags -> PackageDescription
>                -> LocalBuildInfo -> IO ()
> creplChildCopy args flags desc buildinfo = do
>   let Distribution.Simple.Setup.Flag dest = copyDest flags
>   print "copy hook"
>   let dirs = absoluteInstallDirs desc buildinfo (dest)
>   print ("copying child to ", libexecdir dirs </> creplChildName)
>   copyFileVerbose (normal) (creplChildPath buildinfo)
>                   (libexecdir dirs </> creplChildName)

> buildHooks = simpleUserHooks {
>   hookedPrograms = [gccProgram],
>   postBuild = creplChildBuild,
>   postCopy = creplChildCopy
> }

> main = defaultMainWithHooks buildHooks
