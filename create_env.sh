#!/bin/bash

# developer enviroment creator script
# variables ------------------------------------------------------------------------------------------------------

ECLIPSE_IDE="/opt/dev/ide/eclipse"
ECLIPSE_WS="/opt/dev/workspace/eclipse"
TOOLS_DIR="/opt/dev/tools"
PROJECTS_DIR="/opt/dev/projects"
MAVEN_DIR="/opt/dev/maven"
JAVA_DIR="/opt/dev/java/"
DBEAVER_DIR="/opt/dev/tools/dbeaver"

# lists ----------------------------------------------------------------------------------------------------------

declare -A tool_list
declare -A index

tool_list["${JAVA_DIR}"]="https://download.java.net/java/GA/jdk22.0.2/c9ecb94cd31b495da20a27d4581645e8/9/GPL/openjdk-22.0.2_linux-x64_bin.tar.gz"
tool_list["${MAVEN_DIR}"]="https://dlcdn.apache.org/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz"
tool_list["${DBEAVER_DIR}"]="https://dbeaver.io/files/dbeaver-ce-latest-linux.gtk.x86_64-nojdk.tar.gz"
tool_list["${ECLIPSE_IDE}"]="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/2024-09/R/eclipse-jee-2024-09-R-linux-gtk-x86_64.tar.gz&r=1"

index["$ECLIPSE_IDE"]="Eclipse IDE"
index["$JAVA_DIR"]="Java Development Kit (JDK)"
index["$MAVEN_DIR"]="Maven"
index["$DBEAVER_DIR"]="Dbeaver"

# install and create ---------------------------------------------------------------------------------------------

download(){
  local path=$1
  local url=$2
  local name=$3

  echo "  .downloading:"
  
  if [ ! -e "${path}/${name}.tar.gz" ]; then
    sudo wget -q -O "${path}/${name}.tar.gz" "$url"

    if [ $? -ne 0 ]; then
      echo "    .error downloading ${name}, retrying..."
      sudo rm -f "${path}/${name}.tar.gz"  # Remove arquivo corrompido
      return 1
    fi

    # Verifique se o arquivo foi realmente baixado (opcionalmente, adicione uma verificação de checksum)
    if [ ! -s "${path}/${name}.tar.gz" ]; then
      echo "    .download incomplete for ${name}, retrying..."
      sudo rm -f "${path}/${name}.tar.gz"  # Remove arquivo vazio/corrompido
      return 1
    fi

    echo "    .${name} downloaded successfully!"
  else
    echo "    .${name} already downloaded... skipping..."
  fi
}

extract(){
  local path=$1
  local url=$2
  local name=$3

  echo "  .extracting:"
  
  if [ -e "${path}/${name}.tar.gz" ]; then
    sudo tar -xzf "${path}/${name}.tar.gz" -C "${path}" 2>/dev/null

    if [ $? -ne 0 ]; then
      echo "    .error extracting ${name}, removing corrupted file..."
      sudo rm -f "${path}/${name}.tar.gz"  # Remove arquivo corrompido
      return 1
    fi

    echo "    .${name} extracted successfully!"
  else
    echo "    .${name} already extracted... skipping..."
  fi
}

config_tool_name(){
  local name=$1

  case "$name" in
    *"java"*)
      echo "java.exe"
      ;;
    *"maven"*)
      echo "mvn.exe"
      ;;
    *"eclipse"*)
      echo "eclipse.exe"
      ;;
    *"dbeaver"*)
      echo "dbeaver.exe"
      ;;
  esac
}

execute_sh_file(){
  local sh_path=$1
  local sh_name=$2

  /opt/dev/python/Python-3.12.4/install-sh
}

create_environment_variable(){
  local path=$1
  local url=$2
  local name=$3

  tool_name=$(config_tool_name $name)
  tool_extension="${tool_name##*.}"
  tool_basename=$(basename "$tool_name" .exe)

  if [ "$tool_extension" == "exe" ]; then
    echo "  .creating environment variable:"

    maxdepth=1
    while [ $maxdepth -lt 5 ]; do
      exe_path=$(find "$path" -maxdepth $maxdepth -type f -iname "$tool_basename")
      home_path=$(echo "$exe_path" | sed "s|/$tool_basename\$||")
      parent_dir="${home_path%/*}"
      if [ -z "$exe_path" ]; then
        maxdepth=$(( maxdepth + 1 ))
        continue
      else
        home_name="${name^^}_HOME"
        if ! grep -q "${home_name}" ~/.bashrc; then
          if [ $maxdepth == 2 ]; then
            echo export ${home_name}=\"${home_path}\" >>~/.bashrc
            echo export PATH="\$PATH:\$$home_name/" >>~/.bashrc
          else
            echo export ${home_name}=\"${parent_dir}\" >>~/.bashrc
            echo export PATH="\$PATH:\$$home_name/${home_path##*/}" >>~/.bashrc
          fi

          if [ $? -ne 0 ]; then
            echo "    .error creating ${name} environment variable"
            return 1
          fi
          echo "    .${name} environment variable created successfully!"
        else
          echo "    .${name} environment variable already created... skipping..."
        fi

        maxdepth=$(( maxdepth + 1 ))
      fi
    done
  fi
}

install(){
  local to_install=("$@")
  echo "installing tools..."

  declare -A tools
  for tool in "${to_install[@]}"; do 
    tools["${tool}"]="${tool_list[$tool]}"
  done

  for item in "${!tools[@]}"; do
    path=${item}
    url=${tools[$item]}
    name=$(basename "${path}")
    echo "installing ${name}..."
  
    download "$path" "$url" "$name"
    if [ $? -ne 0 ]; then
      rm "$path"
      continue
    fi

    extract "$path" "$url" "$name"
    if [ $? -ne 0 ]; then
      rm "$path"
      continue
    fi

    create_environment_variable "$path" "$url" "$name"
    if [ $? -ne 0 ]; then
      rm "$path"
      continue
    fi
    
    echo "${name} installed successfully!"
    source ~/.bashrc
  done

  sleep 1
}

create_directories(){
  local directories=("$@")

  echo "creating directories:"

  for dir in "${directories[@]}"; do
    if [ -e \$dir ]; then
      echo "  .dir $dir already created... skipping..."
      continue
    fi

    sudo mkdir -p "$dir"
    if [ $? -ne 0 ]; then
      echo "  .error creating dir: $dir"
      continue
    fi 

    echo "  .dir $dir created"
  done

  echo "all directories verified successfully!"
  sleep 1
}

backend_installation() {
  case $? in
    0)
      directories=(
        "$ECLIPSE_IDE" 
        "$ECLIPSE_WS"
        "$TOOLS_DIR"
        "$PROJECTS_DIR"
        "$MAVEN_DIR"
        "$JAVA_DIR"
		"$DBEAVER_DIR"
		)
      create_directories "${directories[@]}"
      sleep 1

	  to_install=("$ECLIPSE_IDE" "$DBEAVER_DIR" "$MAVEN_DIR" "$JAVA_DIR")
      install "${to_install[@]}"
      sleep 1

      return 0
      ;;
  esac
}

# main routine ---------------------------------------------------------------------------------------------------

sudo ls /root

echo "Starting..."
backend_installation

