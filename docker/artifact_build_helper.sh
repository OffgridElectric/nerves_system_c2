set_artifact_env()
{
    export MIX_TARGET=c2
    export MIX_ENV=prod
}

build()
{
    set_artifact_env
    WS=/work/nerves_system_c2
    cd $WS ; mix deps.get
    cd $WS/test_c2 ; mix deps.get
    mix firmware
    cd $WS ; mix nerves.artifact
}