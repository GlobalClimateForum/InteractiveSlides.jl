# https://github.com/GenieFramework/Stipple.jl/issues/148

function Stipple.root(app::Type{M})::String where {M<:Stipple.ReactiveModel}
    "pmodel"
end

# below code disables the default behavior of generating a session file (just in order to reduce general overhead)

function Stipple.sessionid(; encrypt::Bool = true) :: String
  ""
end

function Stipple.ModelStorage.Sessions.GenieSession.load(session_id::String)
    Stipple.ModelStorage.Sessions.GenieSession.Session("", Dict{Symbol,Any}())
end

function Stipple.ModelStorage.Sessions.GenieSessionFileSession.write(session::Stipple.ModelStorage.Sessions.GenieSession.Session)
    Stipple.ModelStorage.Sessions.GenieSession.Session("", Dict{Symbol,Any}())
end

function Stipple.ModelStorage.Sessions.GenieSessionFileSession.read(session_id::String)
    nothing
end