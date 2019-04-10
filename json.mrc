;==================== JSON Aliases =====================
;=======================================================
#SReject/JSONForMirc/CompatMode off
alias JSONUrlMethod {
  if ($isid) return
  JSONHttpMethod $1-
}
alias JSONUrlHeader {
  if ($isid) return
  JSONHttpHeader $1-
}
alias JSONUrlGet {
  if ($isid) return
  JSONHttpFetch $1-
}
#SReject/JSONForMirc/CompatMode end
on *:LOAD:{
  if ($~adiircexe) {
    if ($version < 2.7) {
      echo -ag [JSON For mIRC] AdiIRC v2.7 or later is required
      .unload -rs $qt($script)
    }
  }
  elseif ($version < 7.44) {
    echo -ag [JSON For mIRC] mIRC v7.44 or later is required
    .unload -rs $qt($script)
  }
  else JSONShutdown
}
on *:CLOSE:@SReject/JSONForMirc/Log:if ($jsondebug) jsondebug off
on *:EXIT:JSONShutDown
on *:UNLOAD:{
  .disable #SReject/JSONForMirc/CompatMode
  JSONShutDown
}
menu @SReject/JSONForMirc/Log {
  .Clear: clear -@ $window
  .-
  .$iif(!$jfm_SaveDebug,$style(2)) Save:jfm_SaveDebug
  .-
  .Toggle Debug:JSONDebug
  .-
  .Close:JSONDebug off | close -@ $window
}
alias JSONOpen {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Switches,%Error,%Com $false,%Type text,%HttpOptions 0,%BVar,%BUnset $true
  jfm_log -I /JSONOpen $1-
  if (-* iswm $1) {
    %Switches = $mid($1,2-)
    tokenize 32 $2-
  }
  if ($jfm_ComInit) %Error = $v1
  elseif ($regex(%Switches,([^dbfuUw]))) %Error = SWITCH_INVALID: $+ $regml(1)
  elseif ($regex(%Switches,([dbfuUw]).*?\1)) %Error = SWITCH_DUPLICATE: $+ $regml(1)
  elseif ($regex(%Switches,/([bfuU])/g) > 1) %Error = SWITCH_CONFLICT: $+ $regml(1)
  elseif (u !isin %Switches) && (w isincs %Switches) {
    %Error = SWITCH_NOT_APPLICABLE:w
  }
  elseif ($0 < 2) %Error = PARAMETER_MISSING
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = NAME_INVALID
  elseif ($com(JSON: $+ $1)) %Error = NAME_INUSE
  elseif (u isin %Switches) && ($0 != 2) {
    %Error = PARAMETER_INVALID:URL_SPACES
  }
  elseif (b isincs %Switches) && ($0 != 2) {
    %Error = PARAMETER_INVALID:BVAR
  }
  elseif (b isincs %Switches) && (&* !iswm $2) {
    %Error = PARAMETER_INVALID:NOT_BVAR
  }
  elseif (b isincs %Switches) && (!$bvar($2,0)) {
    %Error = PARAMETER_INVALID:BVAR_EMPTY
  }
  elseif (f isincs %Switches) && (!$isfile($2-)) {
    %Error = PARAMETER_INVALID:FILE_DOESNOT_EXIST
  }
  else {
    %Com = JSON: $+ $1
    %BVar = $jfm_TmpBVar
    if (b isincs %Switches) {
      %Bvar = $2
      %BUnset = $false
    }
    elseif (u isin %Switches) {
      if (w isincs %Switches) inc %HttpOptions 1
      if (U isincs %Switches) inc %HttpOptions 2
      %Type = http
      bset -t %BVar 1 $2
    }
    elseif (f isincs %Switches) bread $qt($file($2-).longfn) 0 $file($file($2-).longfn).size %BVar
    else bset -t %BVar 1 $2-
    %Error = $jfm_Create(%Com,%Type,%BVar,%HttpOptions)
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%BUnset) bunset %BVar
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    if (%Com) && ($com(%Com)) {
      .timer $+ %Com -iom 1 0 JSONClose $unsafe($1)
    }
    jfm_log -EeD %Error
  }
  else {
    if (d isincs %Switches) .timer $+ %Com -iom 1 0 JSONClose $unsafe($1)
    jfm_log -EsD Created $1 (as com %Com $+ )
  }
}
alias JSONHttpMethod {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Com,%Method
  jfm_log -I /JSONHttpMethod $1-
  if ($jfm_ComInit) %Error = $v1
  elseif ($0 < 2) %Error = PARAMETER_MISSING
  elseif ($0 > 2) %Error = PARAMETER_INVALID
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = NAME_INVALID
  elseif (!$com(JSON: $+ $1)) %Error = HANDLE_DOES_NOT_EXIST
  else {
    %Com = JSON: $+ $1
    %Method = $regsubex($2,/(^\s+)|(\s*)$/g,)
    if (!$len(%Method)) %Error = INVALID_METHOD
    elseif ($jfm_Exec(%Com,httpSetMethod,%Method)) %Error = $v1
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else jfm_log -EsD Set Method to $+(',%Method,')
}
alias JSONHttpHeader {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Com,%Header
  jfm_log -I /JSONHttpHeader $1-
  if ($jfm_ComInit) %Error = $v1
  elseif ($0 < 3) %Error = PARAMETER_MISSING
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = INVALID_NAME
  elseif (!$com(JSON: $+ $1)) %Error = HANDLE_DOES_NOT_EXIST
  else {
    %Com = JSON: $+ $1
    %Header = $regsubex($2,/(^\s+)|(\s*:\s*$)/g,)
    if (!$len($2)) %Error = HEADER_EMPTY
    elseif ($regex($2,[\r:\n])) %Error = HEADER_INVALID
    elseif ($jfm_Exec(%Com,httpSetHeader,%Header,$3-)) %Error = $v1
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else jfm_log -EsD Stored Header $+(',%Header,: $3-,')
}
alias JSONHttpFetch {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Switches,%Error,%Com,%BVar,%BUnset
  jfm_log -I /JSONHttpFetch $1-
  if (-* iswm $1) {
    %Switches = $mid($1,2-)
    tokenize 32 $2-
  }
  if ($jfm_ComInit) %Error = $v1
  if ($0 == 0) || (%Switches != $null && $0 < 2) {
    %Error = PARAMETER_MISSING
  }
  elseif ($regex(%Switches,([^bf]))) %Error = SWITCH_INVALID: $+ $regml(1)
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = NAME_INVALID
  elseif (!$com(JSON: $+ $1)) %Error = HANDLE_DOES_NOT_EXIST
  elseif (b isincs %Switches) && (&* !iswm $2 || $0 > 2) {
    %Error = BVAR_INVALID
  }
  elseif (f isincs %Switches) && (!$isfile($2-)) {
    %Error = FILE_DOESNOT_EXIST
  }
  else {
    %Com = JSON: $+ $1
    if ($0 > 1) {
      %BVar = $jfm_tmpbvar
      %BUnset = $true
      if (b isincs %Switches) {
        %BVar = $2
        %BUnset = $false
      }
      elseif (f isincs %Switches) bread $qt($file($2-).longfn) 0 $file($2-).size %BVar
      else bset -t %BVar 1 $2-
      %Error = $jfm_Exec(%Com,httpSetData,& %BVar).fromBvar
    }
    if (!%Error) %Error = $jfm_Exec(%Com,parse)
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%BUnset) bunset %BVar
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else jfm_log -EsD Http Data retrieved
}
alias JSONClose {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Switches,%Error,%Match,%Com,%X 1
  jfm_log -I /JSONClose $1-
  if (-* iswm $1) {
    %Switches = $mid($1,2-)
    tokenize 32 $2-
  }
  if ($0 < 1) %Error = PARAMTER_MISSING
  elseif ($0 > 1) %Error = PARAMETER_INVALID
  elseif ($regex(%Switches,/([^w])/)) %Error = SWITCH_UNKNOWN: $+ $regml(1)
  elseif (: isin $1) && (w isincs %Switches || JSON:* !iswmcs $1) {
    %Error = PARAMETER_INVALID
  }
  else {
    %Match = $1
    if (JSON:* iswmcs $1) %Match = $gettok($1,2-,58)
    %Match = $replacecs(%Match,\E,\E\\E\Q)
    if (w isincs %Switches) %Match = $replacecs(%Match,?,\E[^:]\Q,*,\E[^:]*\Q)
    %Match = /^JSON:\Q $+ %Match $+ \E(?::\d+)?$/i
    %Match = $replacecs(%Match,\Q\E,)
    while (%X <= $com(0)) {
      %Com = $com(%X)
      if ($regex(%Com,%Match)) {
        .comclose %Com
        if ($timer(%Com)) .timer $+ %Com off
        jfm_log Closed %Com
      }
      else inc %X
    }
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD /JSONClose %Error
  }
  else jfm_log -D
}
alias JSONList {
  if ($isid) return
  var %X 1,%I 0
  jfm_log /JSONList $1-
  while ($com(%X)) {
    if (JSON:?* iswm $v1) {
      inc %I
      echo $color(info) -age * $chr(35) $+ %I $+ : $v2
    }
    inc %X
  }
  if (!%I) echo $color(info) -age * No active JSON handlers
}
alias JSONShutDown {
  if ($isid) return
  JSONClose -w *
  if ($JSONDebug) JSONDebug off
  if ($window(@SReject/JSONForMirc/Log)) close -@ $v1
  if ($com(SReject/JSONForMirc/JSONEngine)) .comclose $v1
  if ($com(SReject/JSONForMirc/JSONShell)) .comclose $v1
  if ($hget(SReject/JSONForMirc)) hfree $v1
}
alias JSONCompat {
  if ($isid) return $iif($group(#SReject/JSONForMirc/CompatMode) == on,$true,$false)
  .enable #SReject/JSONForMirc/CompatMode
}
alias JSON {
  if (!$isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %X 1,%Args,%Params,%Error,%Com,%I 0,%Prefix,%Prop,%Suffix,%Offset $iif(*toFile iswm $prop,3,2),%Type,%Output,%Result,%ChildCom,%Call
  while (%X <= $0) {
    %Args = %Args $+ $iif($len(%Args),$chr(44)) $+ $($ $+ %X,2)
    if (%X >= %Offset) %Params = %Params $+ ,bstr,$ $+ %X
    inc %X
  }
  %X = 1
  jfm_log -I $!JSON( $+ %Args $+ ) $+ $iif($len($prop),. $+ $prop)
  if (!$0) || ($0 == 1 && $1 == $null) {
    %Error = MISSING_PARAMETERS
    goto error
  }
  if ($0 == 1) && ($1 == 0) && ($prop !== $null) {
    %Error = PROP_NOT_APPLICABLE
    goto error
  }
  if ($regex(name,$1,/^JSON:[^:?*]+(?::\d+)?$/i)) %Com = $1
  elseif (: isin $1 || * isin $1 || ? isin $1) || ($1 == 0 && $0 !== 1) {
    %Error = INVALID_NAME
  }
  elseif ($regex($1,/^\d+$/)) {
    while ($com(%X)) {
      if ($regex($v1,/^JSON:[^:]+$/)) {
        inc %I
        if (%I === $1) {
          %Com = $com(%X)
          break
        }
      }
      inc %X
    }
    if ($1 === 0) {
      jfm_log -EsD %I
      return %I
    }
  }
  else %Com = JSON: $+ $1
  if (!%Error) && (!$com(%Com)) {
    %Error = HANDLER_NOT_FOUND
  }
  elseif (* isin $prop) || (? isin $prop) {
    %Error = INVALID_PROP
  }
  else {
    if ($regex($prop,/^((?:fuzzy)?)(.*?)((?:to(?:bvar|file))?)?$/i)) {
      %Prefix = $regml(1)
      %Prop   = $regml(2)
      %Suffix = $regml(3)
    }
    %Prop = $regsubex(%Prop,/^url/i,http)
    if ($JSONCompat) {
      if (%Prop == status) %Prop = state
      if (%Prop == data) %Prop = input
      if (%Prop == isRef) %Prop = isChild
      if (%Prop == isParent) %Prop = isContainer
    }
    if (%Suffix == tofile) {
      if ($0 < 2) %Error = INVALID_PARAMETERS
      elseif (!$len($2) || $isfile($2) || (!$regex($2,/[\\\/]/) && " isin $2)) {
        %Error = INVALID_FILE
      }
      else %Output = $longfn($2)
    }
  }
  if (%Error) goto error
  elseif ($0 == 1) && (!$prop) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 %Com
  }
  elseif (%Prop == isChild) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 $iif(JSON:?*:?* iswm %Com,$true,$false)
  }
  elseif ($wildtok(state|error|input|inputType|httpParse|httpHead|httpStatus|httpStatusText|httpHeaders|httpBody|httpResponse,%Prop,1,124)) {
    if ($jfm_Exec(%Com,$v1)) %Error = $v1
    else %Result = $hget(SReject/JSONForMirc,Exec)
  }
  elseif (%Prop == httpHeader) {
    if ($calc($0 - %Offset) < 0) %Error = INVALID_PARAMETERS
    elseif ($jfm_Exec(%Com,httpHeader,$($ $+ %Offset,2))) %Error = $v1
    else %Result = $hget(SReject/JSONForMirc,Exec)
  }
  elseif (%Prop == $null) || ($wildtok(path|pathLength|type|isContainer|length|value|string|debug,%Prop,1,124)) {
    %Prop = $v1
    if ($0 >= %Offset) {
      %ChildCom = JSON: $+ $gettok(%Com,2,58) $+ :
      %X = $ticks
      while ($com(%ChildCom $+ %X)) inc %X
      %ChildCom = %ChildCom $+ %X
      %Call = $!com( $+ %Com $+ ,walk,1,bool, $+ $iif(fuzzy == %Prefix,$true,$false) $+ %Params $+ ,dispatch* %ChildCom $+ )
      jfm_log %Call
      if (!$eval(%Call,2)) || ($comerr) || (!$com(%ChildCom)) {
        %Error = $jfm_GetError
        goto error
      }
      .timer $+ %ChildCom -iom 1 0 JSONClose %ChildCom
      %Com = %ChildCom
      jfm_log
    }
    if ($JSONCompat) && ($prop == $null) {
      if ($jfm_exec(%Com,type)) %Error = $v1
      elseif ($bvar($hget(SReject/JSONForMirc,Exec),1-).text == object) || ($v1 == array) {
        %Result = $jfm_TmpBvar
        bset -t %Result 1 %Com
      }
      elseif ($jfm_Exec(%Com,value)) %Error = $v1
      else %Result = $hget(SReject/JSONForMirc,Exec)
    }
    elseif (!%Prop) {
      %Result = $jfm_TmpBvar
      bset -t %Result 1 %Com
    }
    elseif (%Prop !== value) {
      if ($jfm_Exec(%Com,$v1)) %Error = $v1
      else %Result = $hget(SReject/JSONForMirc,Exec)
    }
    elseif ($jfm_Exec(%Com,type)) %Error = $v1
    elseif ($bvar($hget(SReject/JSONForMirc,Exec),1-).text == object) || ($v1 == array) {
      %Error = INVALID_TYPE
    }
    elseif ($jfm_Exec(%Com,value)) %Error = $v1
    else %Result = $hget(SReject/JSONForMirc,Exec)
  }
  else %Error = UNKNOWN_PROP
  if (!%Error) {
    if (%Suffix == tofile) {
      bwrite $qt(%Output) -1 -1 %Result
      bunset %Result
      %Result = %Output
    }
    elseif (%Suffix !== tobvar) %Result = $bvar(%Result,1,4000).text
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else {
    jfm_log -EsD %Result
    return %Result
  }
}
alias JSONForEach {
  if (!$isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Log,%Call,%X 0,%JSON,%Com,%ChildCom,%Result 0,%Name
  %Log = $!JSONForEach(
  %Call = ,forEach,1,bool, $+ $iif(walk == $prop,$true,$false) $+ ,bool, $+ $iif(fuzzy == $prop,$true,$false)
  :next
  if (%X < $0) {
    inc %X
    %Log = %Log $+ $($ $+ %X,2) $+ ,
    if (%X > 2) %Call = %Call $+ ,bstr, $+ $ $+ %X
    goto next
  }
  jfm_log -I $left(%Log,-1) $+ $chr(41) $+ $iif($prop !== $null,. $+ $v1)
  if ($0 < 2) %Error = INVAID_PARAMETERS
  elseif ($1 == 0) %Error = INVALID_HANDLER
  elseif ($prop !== $null) && ($prop !== walk) && ($prop !== fuzzy) {
    %Error = INVALID_PROPERTY
  }
  elseif ($0 > 2) && ($prop == walk) {
    %Error = PARAMETERS_NOT_APPLICABLE
  }
  elseif (!$1) || ($1 == 0) || (!$regex($1,/^((?:[^?:*]+)|(?:JSON:[^?:*]+(?::\d+)))$/)) {
    %Error = NAME_INVALID
  }
  else {
    if (JSON:?* iswm $1) %JSON = $com($1)
    elseif ($regex($1,/^\d+$/i)) {
      %X = 1
      %JSON = 0
      while ($com(%X)) {
        if ($regex($1,/^JSON:[^?*:]+$/)) {
          inc %JSON
          if (%JSON == $1) {
            %JSON = $com(%X)
            break
          }
          elseif (%X == $com(0)) %JSON = $null
        }
        inc %X
      }
    }
    else %JSON = $com(JSON: $+ $1)
    if (!%JSON) %Error = HANDLE_NOT_FOUND
    else {
      %Com = $gettok(%JSON,1-2,58) $+ :
      %X = $ticks
      :next2
      if ($com(%Com $+ %X)) {
        inc %X
        goto next2
      }
      %Com = %Com $+ %X
      %Call = $!com( $+ %JSON $+ %Call $+ ,dispatch* %Com $+ )
      jfm_log %Call
      if (!$(%Call,2)) || ($comerr) || (!$com(%Com)) {
        %Error = $jfm_GetError
      }
      else {
        .timer $+ %Com -iom 1 0 JSONClose $unsafe(%Com)
        if (!$com(%Com,length,2)) || ($comerr) {
          %Error = $jfm_GetError
        }
        elseif ($com(%Com).result) {
          %Result = $v1
          %X = 0
          while (%X < %Result) {
            %ChildCom = $gettok(%Com,1-2,58) $+ :
            %Name = $ticks
            :next3
            if ($com(%ChildCom $+ %Name)) {
              inc %Name
              goto next3
            }
            %Name = %ChildCom $+ %Name
            if (!$com(%Com,%X,2,dispatch* %Name)) || ($comerr) || (!$com(%Name)) {
              %Error = $jfm_GetError
              break
            }
            else {
              jfm_log -I Calling $iif(/ $+ * !iswm $2,/) $+ $2 %Name
              .timer $+ %Name -iom 1 0 JSONClose $unsafe(%Name)
              $2 %Name
              jfm_log -D
            }
            inc %X
          }
        }
      }
    }
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%Error) {
    if ($com(%Com)) .comclose $v1
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else {
    jfm_log -EsD %Result
    return %Result
  }
}
alias JSONPath {
  if (!$isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Param,%X 0,%JSON,%Result
  while (%X < $0) {
    inc %X
    %Param = %Param $+ $($ $+ %X,2) $+ ,
  }
  jfm_log -I $!JSONPath( $+ $left(%Param,-1) $+ )
  if ($0 !== 2) %Error = INVALID_PARAMETERS
  elseif ($prop !== $null) %Error = PROP_NOT_APPLICABLE
  elseif (!$1) || ($1 == 0) || (!$regex($1,/^(?:(?:JSON:[^?:*]+(?::\d+)*)?|([^?:*]+))$/i)) {
    %Error = NAME_INVALID
  }
  elseif ($2 !isnum 0-) || (. isin $2) {
    %Error = INVALID_INDEX
  }
  else {
    %JSON = $JSON($1)
    if ($JSONError) %Error = $v1
    elseif (!%JSON) %Error = HANDLER_NOT_FOUND
    elseif ($JSON(%JSON).pathLength == $null) %Error = $JSONError
    else {
      %Result = $v1
      if (!$2) noop
      elseif ($2 > %Result) unset %Result
      elseif (!$com(%JSON,pathAtIndex,1,bstr,$calc($2 -1))) || ($comerr) {
        %Error = $jfm_GetError
      }
      else %Result = $com(%JSON).result
    }
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD %Error
  }
  else {
    jfm_log -EsD %Result
    return %Result
  }
}
alias JSONError if ($isid) return $hget(SReject/JSONForMirc,Error)
alias JSONVersion {
  if ($isid) {
    var %Ver = 1.0.3006
    if ($0) return %Ver
    return SReject/JSONForMirc v $+ %Ver
  }
}
alias JSONDebug {
  var %State = $false,%aline = aline $color(info2) @SReject/JSONForMirc/Log
  if ($group(#SReject/JSONForMirc/Log) == on) {
    if (!$window(@SReject/JSONForMirc/Log)) .disable #SReject/JSONForMirc/log
    else %State = $true
  }
  if ($isid) return %State
  elseif (!$0) || ($1 == toggle) {
    if (%State) tokenize 32 disable
    else tokenize 32 enable
  }
  if ($1 == on) || ($1 == enable) {
    if (%State) {
      echo $color(info).dd -atngq * /JSONDebug: debug already enabled
      return
    }
    .enable #SReject/JSONForMirc/Log
    %State = $true
  }
  elseif ($1 == off) || ($1 == disable) {
    if (!%State) {
      echo $color(info).dd -atngq * /JSONDebug: debug already disabled
      return
    }
    .disable #SReject/JSONForMirc/Log
    %State = $false
  }
  else {
    echo $color(info).dd -atng * /JSONDebug: Unknown input
    return
  }
  if (%State) {
    if (!$window(@SReject/JSONForMirc/Log)) window -zk0e @SReject/JSONForMirc/Log
    %aline Debug now enabled
    if ($~adiircexe) %aline AdiIRC v $+ $version $iif($beta,beta $builddate) $bits $+ bit
    else %aline mIRC v $+ $version $iif($beta,beta $v1) $bits $+ bit
    %aline $JSONVersion $iif($JSONCompat,[CompatMode],[NormalMode])
    %aline -
  }
  elseif ($Window(@SReject/JSONForMirc/Log)) %aline [JSONDebug] Debug now disabled
  window -b @SReject/JSONForMirc/Log
}
alias -l jfm_TmpBVar {
  var %N = $ticks
  jfm_log -I $!jfm_TmpBVar
  :next
  if (!$bvar(&SReject/JSONForMirc/Tmp $+ %N)) {
    jfm_log -EsD &SReject/JSONForMirc/Tmp $+ %N
    return &SReject/JSONForMirc/Tmp $+ %N
  }
  inc %N
  goto next
}
alias -l jfm_ComInit {
  var %Error,%Js = $jfm_tmpbvar
  jfm_log -I $!jfm_ComInit
  if ($com(SReject/JSONForMirc/JSONShell) && $com(SReject/JSONForMirc/JSONEngine)) {
    jfm_log -EsD Already Initialized
    return
  }
  jfm_jscript %Js
  if ($com(SReject/JSONForMirc/JSONEngine)) .comclose $v1
  if ($com(SReject/JSONForMirc/JSONShell)) .comclose $v1
  if ($~adiircexe !== $null) && ($bits == 64) {
    .comopen SReject/JSONForMirc/JSONShell ScriptControl
  }
  else {
    .comopen SReject/JSONForMirc/JSONShell MSScriptControl.ScriptControl
  }
  if (!$com(SReject/JSONForMirc/JSONShell)) || ($comerr) {
    %Error = SCRIPTCONTROL_INIT_FAIL
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell,language,4,bstr,jscript)) || ($comerr) {
    %Error = LANGUAGE_SET_FAIL
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell,AllowUI,4,bool,$false)) || ($comerr) {
    %Error = ALLOWIU_SET_FAIL
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell,timeout,4,integer,-1)) || ($comerr) {
    %Error = TIMEOUT_SET_FAIL
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell,ExecuteStatement,1,&bstr,%Js)) || ($comerr) {
    %Error = JSCRIPT_EXEC_FAIL
  }
  elseif (!$com(SReject/JSONForMirc/JSONShell,Eval,1,bstr,this,dispatch* SReject/JSONForMirc/JSONEngine)) || ($comerr) || (!$com(SReject/JSONForMirc/JSONEngine)) {
    %Error = ENGINE_GET_FAIL
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    if ($com(SReject/JSONForMirc/JSONEngine)) .comclose $v1
    if ($com(SReject/JSONForMirc/JSONShell)) .comclose $v1
    jfm_log -EeD %Error
    return %Error
  }
  else jfm_log -EsD Successfully initialized
}
alias -l jfm_GetError {
  var %Error = UNKNOWN
  jfm_log -I $!jfm_GetError
  if ($com(SReject/JSONForMirc/JSONShell).errortext) %Error = $v1
  if ($com(SReject/JSONForMirc/JSONShellError)) .comclose $v1
  if ($com(SReject/JSONForMirc/JSONShell,Error,2,dispatch* SReject/JSONForMirc/JSONShellError)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError)) && ($com(SReject/JSONForMirc/JSONShellError,Description,2)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError).result !== $null) {
    %Error = $v1
  }
  if ($com(SReject/JSONForMirc/JSONShellError)) .comclose $v1
  jfm_log -EsD %Error
  return %Error
}
alias -l jfm_Create {
  var %Wait $iif(1 & $4,$true,$false),%Parse $iif(2 & $4,$false,$true),%Error
  jfm_log -I $!jfm_create( $+ $1 $+ , $+ $2 $+ , $+ $3 $+ , $+ $4)
  if (!$com(SReject/JSONForMirc/JSONEngine,JSONCreate,1,bstr,$2,&bstr,$3,bool,%Parse,dispatch* $1)) || ($comerr) || (!$com($1)) {
    %Error = $jfm_GetError
  }
  elseif ($2 !== http || ($2 == http && !%Wait)) && (!$com($1,parse,1)) {
    %Error = $jfm_GetError
  }
  if (%Error) {
    jfm_log -EeD %Error
    return %Error
  }
  jfm_log -EsD Created $1
}
alias -l jfm_Exec {
  var %Args,%Index 1,%Params,%Error
  if ($hget(SReject/JSONForMirc,Exec)) hdel SReject/JSONForMirc Exec
  :args
  if (%Index <= $0) {
    %Args = %Args $+ $iif($len(%Args),$chr(44)) $+ $($ $+ %Index,2)
    if (%Index >= 3) {
      if ($prop == fromBvar) && ($regex($($ $+ %Index,2),/^& (&\S+)$/)) {
        %Params = %Params $+ ,&bstr, $+ $regml(1)
      }
      else %Params = %Params $+ ,bstr,$ $+ %Index
    }
    inc %Index
    goto args
  }
  %Params = $!com($1,$2,1 $+ %Params $+ )
  jfm_log -I $!jfm_Exec( $+ %Args $+ )
  if (!$(%Params,2)) || ($comerr) {
    %Error = $jfm_GetError
    jfm_log -EeD %Error
    return %Error
  }
  else {
    hadd -mu0 SReject/JSONForMirc Exec $jfm_tmpbvar
    noop $com($1,$hget(SReject/JSONForMirc,Exec)).result
    jfm_log -EsD Result stored in $hget(SReject/JSONForMirc,Exec)
  }
}
#SReject/JSONForMirc/Log off
alias -l jfm_log {
  var %Switches,%Prefix ->,%Color = 03,%Indent
  if (!$window(@SReject/JSONForMirc/Log)) {
    .JSONDebug off
    if ($hget(SReject/JSONForMirc,LogIndent)) { hdel SReject/JSONForMirc LogIndent }
  }
  else {
    if (-?* iswm $1) {
      %Switches = $mid($1,2-)
      tokenize 32 $2-
    }
    if (i isincs %Switches) hinc -mu1 SReject/JSONForMirc LogIndent
    if ($0) {
      if (E isincs %Switches) %Prefix = <-
      if (e isincs %Switches) %Color = 04
      elseif (s isincs %Switches) %Color = 12
      elseif (l isincs %Switches) %Color = 13
      %Prefix = $chr(3) $+ %Color $+ %Prefix $+ $chr(15)
      %Indent = $str($chr(15) $+ $chr(32),$calc($hget(SReject/JSONForMirc,LogIndent) *4))
      echo -gi $+ $calc(($hget(SReject/JSONForMirc,LogIndent) + 1) * 4 -1) @SReject/JSONForMirc/Log %Indent %Prefix $1-
    }
    if (I isincs %Switches) hinc -mu1 SReject/JSONForMirc LogIndent 1
    if (D isincs %Switches) && ($hget(SReject/JSONForMirc,LogIndent) > 0) {
      hdec -mu1 SReject/JSONForMirc LogIndent 1
    }
  }
}
#SReject/JSONForMirc/Log end
alias -l jfm_log noop
alias -l jfm_SaveDebug {
  if ($isid) {
    if ($window(@SReject/JSONForMirc/Log)) && ($line(@SReject/JSONForMirc/Log,0)) return $true
    return $false
  }
  var %File $sfile($envvar(USERPROFILE) $+ \Documents\JSONForMirc.log,JSONForMirc - Debug window,Save)
  if (%File) && (!$isfile(%File) || $input(Are you sure you want to overwrite $nopath(%File) $+ ?,qysa,@SReject/JSONForMirc/Log,Overwrite)) {
    savebuf @SReject/JSONForMirc/Log $qt(%File)
  }
}
alias -l jfm_badd bset -t $1 $calc(1 + $bvar($1,0)) $2-
alias -l jfm_jscript {
  var %badd jfm_badd $1
  %badd (function(){function getType(o){if(o===null)return'null';return Object.prototype.toString.call(o).match(/^\[object ([^\]]+)\]$/)[1].toLowerCase()}function hasOwnProp(o,p){return Object.prototype.hasOwnProperty.call(o,p)}function parsed(s){if(s._state!=='done'||s._error||!s._parse)throw new Error('NOT_PARSED');return s}function httpPending(s){if(s._type!=='http')throw new Error('HTTP_NOT_INUSE');if(s._state!=='http_pending')throw new Error('HTTP_NOT_PENDING');return s._http}function httpDone(s){if(s._type!=='http')throw new Error('HTTP_NOT_INUSE');if(s._state!=='done')throw new Error('HTTP_PENDING');return s._http}function JSONWrapper(p,j,s){s=this;if(p===undefined)p={};if(j===undefined){s._isChild=!1;s._json=p._json||{}}else{s._isChild=!0;s._json=j}s._state=p._state||'init';s._type=p._type||'text';s._parse=p._parse===!1?!1:!0;s._error=p._error||!1;s._input=p._input;s._http=p._http||{method:'GET',url:'',headers:[]}}Array.prototype.forEach=function(c){for(var s=this,i=0;i<s.length;i++)c.call(s,s[i],i)};Array.prototype.find=function(c){for(var s=this,i=0;i<s.length;i++)if(c.call(s,s[i]))return s[i]};Object.keys=function(o){var k=[],i;for(i in o)if(hasOwnProp(o,i))k.push(i);return k};HTTPObject=['MSXML2.SERVERXMLHTTP.6.0','MSXML2.SERVERXMLHTTP.3.0','MSXML2.SERVERXMLHTTP'].find(function(x,t){try{t=new ActiveXObject(x);return x}catch(e){}});(JSON={}).parse=function(i){try {i=String(i).replace(/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,function(c){return'\\u'+('0000'+c.charCodeAt(0).toString(16)).slice(-4)});if(/^[\],:{}\s]*$/.test(i.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,''))) {return eval('('+i+')')}}catch(e){}throw new Error("INVALID_JSON")};JSON.stringify=function(v){var t=getType(v),o='[';if(v===undefined||t==='function')return;if(v===null)return'null';if(t==='number')return isFinite
  %badd (v)?v.toString():'null';if(t==='boolean')return v.toString();if(t==='string')return'"'+v.replace(/[\\"\u0000-\u001F\u2028\u2029]/g,function(c){return{'"':'\\"','\\':'\\\\','\b':'\\b','\f':'\\f','\n':'\\n','\r':'\\r','\t':'\\t'}[c]||'\\u'+(c.charCodeAt(0)+0x10000).toString(16).substr(1)})+'"';if(t==='array'){v.forEach(function(v,i){v=JSON.stringify(v);if(v)o+=(i?',':'')+v});return o+']'}o=[];Object.keys(v).forEach(function(k,r){r=JSON.stringify(v[k]);if(r)o.push(JSON.stringify(k)+':'+r)});return'{'+o.join(',')+'}'};JSONWrapper.prototype={state:function(){return this._state},error:function(){return this._error.message},inputType:function(){return this._type},input:function(){return this._input||null},httpParse:function(){return this._parse},httpSetMethod:function(m){httpPending(this).method=m},httpSetHeader:function(h,v){httpPending(this).headers.push([h,v])},httpSetData:function(d){httpPending(this).data=d},httpStatus:function(){return httpDone(this).response.status},httpStatusText:function(){return httpDone(this).response.statusText},httpHeaders:function(){return httpDone(this).response.getAllResponseHeaders()},httpHeader:function(h){return httpDone(this).response.getResponseHeader(h)},httpBody:function(){return httpDone(this).response.responseBody},httpHead:function(){return this.httpStatus()+' '+this.httpStatusText()+'\r\n'+this.httpHeaders()},httpResponse:function(){return this.httpHead()+'\r\n\r\n'+this.httpBody()},parse:function(s){s=this;s.parse=function(){throw new Error('PARSE_NOT_PENDING')};s._state='done';try{if(s._type==='http'){try{var d=!0,l,t=l=!1,r=new ActiveXObject(HTTPObject);if(s._http.data==undefined){d=!1;s._http.data=null}r.setTimeouts(30000,60000,60000,60000);r.open(s._http.method,s._http.url,!1);s._http.headers.forEach(function(h){r.setRequestHeader(h[0],h[1]);if(h[0].toLowerCase()==="content-type")t=!0;if(h[0].toLowerCase()==="content-length")l=!0});if(d){if(!t)r.setRequestHeader("Content-Type","application/x-www-form-urlencoded");if(!l){if(
  %badd s._http.data==null)r.setRequestHeader("Content-Length",0);else r.setRequestHeader("Content-Length",String(s._http.data).length)}}r.send(s._http.data);s._http.response=r;if(s._parse===!1)return s;s._input=r.responseText}catch (e){e.message="HTTP: "+e.message;throw e}}s._json={path:[],value:JSON.parse(s._input)};return s}catch(e){s._error=e.message;throw e}},walk:function(){var s=parsed(this),r=s._json.value,a=Array.prototype.slice.call(arguments),d=a.shift(),p=s._json.path.slice(0),t,m,f,k;while(a.length){t=getType(r);if(t!=='array'&&t!=='object')throw new Error('ILLEGAL_REFERENCE');m=String(a.shift());if(d&&t=='object'&&/^[~=]./.test(m)){f='~'===m.charAt(0);m=m.replace(/^[~=]\x20?/,'');if(f){k=Object.keys(r);if(/^\d+$/.test(m)){m=parseInt(m,10);if(m>=k.length)throw new Error('FUZZY_INDEX_NOT_FOUND');m=k[m]}else if(!hasOwnProp(r,m)){m=m.toLowerCase();m=k.find(function(k){return m===k.toLowerCase()});if(m==undefined)throw new Error('FUZZY_MEMBER_NOT_FOUND')}}}if(!hasOwnProp(r,m))throw new Error('REFERENCE_NOT_FOUND');p.push(m);r=r[m]}return new JSONWrapper(s,{path:p,value:r})},forEach:function(){var s=parsed(this),a=Array.prototype.slice.call(arguments),t=s.type(),r=[],m=a[0]?Infinity:1;a.shift();function R(v,p,j){j=new JSONWrapper(s,{path:p,value:v});if(m!==Infinity&&a.length>1)j=j.walk.apply(j,a.slice(0));r.push(j)}function W(v,p,d){p=p.slice(0);var t=getType(v);if(d>m)R(v,p);else if(t==='object')Object.keys(v).forEach(function(i){var z=p.slice(0);z.push(i);W(v[i],z,d+1)});else if(t==='array')v.forEach(function(v,i){var z=p.slice(0);z.push(i);W(v,z,d+1)});else R(v,p)}if(t!=='object'&&t!=='array')throw new Error('ILLEGAL_REFERENCE');W(s._json.value,s._json.path.slice(0),1);return r},type:function(){return getType(parsed(this)._json.value)},isContainer:function(){return(this.type()==="object"||this.type()==="array")},pathLength:function(){return parsed(this)._json.path.length},pathAtIndex:function(i){return parsed(this)._json.path[i]},path:function(r){r='';parsed(thi
  %badd s)._json.path.forEach(function(i){r+=(r?' ':'')+String(i).replace(/([\\ ])/g,function(c){return' '===chr?'\s':'\\'})});return r},length:function(){var s=parsed(this),t=s.type();if(t==='string'||t==='array')return s._json.value.length;if(t==='object')return Object.keys(s._json.value).length;throw new Error('INVALID_TYPE')},value:function(){return parsed(this)._json.value},string:function(){return JSON.stringify(parsed(this)._json.value)},debug:function(){var s=this,r={state:s._state,input:s._input,type:s._type,error:s._error,parse:s._parse,http:{url:s._http.url,method:s._http.method,headers:s._http.headers,data:s._http.data},isChild:s._isChild,json:s._json};if(s._type==="http"&&s._state==="done")r.http.response={status:s._http.response.status,statusText:s._http.response.statusText,headers:(s._http.response.getAllResponseHeaders()).split(/[\r\n]+/g),responseText:s._http.response.responseText};return JSON.stringify(r)}};JSONCreate=function(t,i,p){var s=new JSONWrapper();s._state='init';s._type=(t||'text').toLowerCase();s._parse=p===!1?!1:!0;if(s._type==='http'){if(!HTTPObject){s._error='HTTP_NOT_FOUND';throw new Error('HTTP_NOT_FOUND')}s._state='http_pending';s._http.url=i}else{s._state='parse_pending';s._input=i}return s}}());
}