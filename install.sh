#!/usr/bin/env bash

cd "$(dirname "$0")"

command="& {./Scripts/Install.ps1; exit \$lastexitcode}"

function version { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

pwsh_major_version="7"
pwsh_minor_version="2"
pwsh_build_version="7"

pwsh_version="${pwsh_major_version}.${pwsh_minor_version}.${pwsh_build_version}"

if [ -x "$(command -v pwsh)" ]; then
  pwsh_version_current="$(pwsh --version | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p')"
fi

for arg in "$@"
do
  if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
    cat << EOF

RainbowMiner Installer v1.2

Commandline options:

  -pv, --pwsh_version   shows version of currently installed powershell
  -pu, --pwsh_update    updates powershell to version ${pwsh_version}
  -h, --help            displays this help page

EOF
    exit
  elif [ "$arg" == "--pwsh_version" ] || [ "$arg" == "-pv" ]; then
    if [ "${pwsh_version_current}" != "" ]; then
      echo ${pwsh_version_current}
    else
      echo "Powershell not installed"
    fi
    exit
  elif [ "$arg" == "--pwsh_update" ] || [ "$arg" == "-pu" ]; then
    if [ "${pwsh_version_current}" != "" ]; then
      if [ $(version ${pwsh_version_current}) -lt $(version ${pwsh_version}) ]; then
        rm -f /usr/bin/pwsh
        printf "\nPowershell will be updated from ${pwsh_version_current} -> ${pwsh_version}\n\n"
      else
        printf "\nPowershell ${pwsh_version_current} already up to date\n\n"
      fi
    else
      printf "\nPowershell not installed, yet\n\n"
    fi
    pwsh_update="1"
  fi
done

if ! [ -x "$(command -v pwsh)" ]; then
  if ps -C pwsh >/dev/null
  then
    printf "Alas! RainbowMiner or another pwsh process is still running. Cannot update.\n\n"
  else
    if [ -L "/usr/bin/pwsh" ]; then
      rm -f /usr/bin/pwsh
    fi
    wget https://github.com/PowerShell/PowerShell/releases/download/v${pwsh_version}/powershell-${pwsh_version}-linux-x64.tar.gz -O /tmp/powershell.tar.gz
     mkdir -p /opt/microsoft/powershell/${pwsh_major_version}
     tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/${pwsh_major_version} --overwrite
     chmod +x /opt/microsoft/powershell/${pwsh_major_version}/pwsh
     ln -s /opt/microsoft/powershell/${pwsh_major_version}/pwsh /usr/bin/pwsh
     rm -f /tmp/powershell.tar.gz
  fi
fi

if [ "${pwsh_update}" == "1" ]; then
  exit
fi

if ! [ -d "/opt/rainbowminer" ]; then
  mkdir -p /opt/rainbowminer
  if ! [ -d "/opt/rainbowminer/ocdcmd" ]; then
    mkdir -p /opt/rainbowminer/ocdcmd
    chmod 777 /opt/rainbowminer/ocdcmd
  fi
fi

chmod +x ./IncludesLinux/bin/*
cp -Rf ./IncludesLinux/* /opt/rainbowminer
chmod +x /opt/rainbowminer/bin/ocdaemon
ln -nfs /opt/rainbowminer/bin/ocdaemon /usr/bin/ocdaemon
/opt/rainbowminer/bin/ocdaemon reinstall

if ! [ -x "$(command -v amdmeminfo)" ]; then
  ln -nfs /opt/rainbowminer/bin/amdmeminfo /usr/bin/amdmeminfo
fi

if ! [ -x "$(command -v wolfamdctrl)" ]; then
  ln -nfs /opt/rainbowminer/bin/wolfamdctrl /usr/bin/wolfamdctrl
fi

if ! [ -x "$(command -v rbmtail)" ]; then
  ln -nfs /opt/rainbowminer/bin/rbmtail /usr/bin/rbmtail
fi

pwsh -ExecutionPolicy bypass -Command ${command}
exitcode=$?
chmod 777 -R $HOME/.local/share/powershell

if [ "$exitcode" == "10" ]; then
  ./start.sh
