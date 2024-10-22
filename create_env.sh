#!/bin/bash

# developer enviroment creator scritp
# variables ------------------------------------------------------------------------------------------------------

LOG_FILE="/tmp/devenv_inst_log.txt"
ECLIPSE_IDE="/opt/dev/ide/eclipse"
ECLIPSE_WS="/opt/dev/workspace/eclipse"
TOOLS_DIR="/opt/dev/tools"
PYTHON_DIR="/opt/dev/python"
PROJECTS_DIR="/opt/dev/projects"
MAVEN_DIR="/opt/dev/maven"
JAVA_DIR="/opt/dev/java/"
DBEAVER_DIR="/opt/dev/tools/dbeaver"

# lists ----------------------------------------------------------------------------------------------------------

declare -A tool_list
declare -A index

tool_list["${JAVA_DIR}"]="https://download.java.net/java/GA/jdk22.0.2/c9ecb94cd31b495da20a27d4581645e8/9/GPL/openjdk-22.0.2_linux-x64_bin.tar.gz"
tool_list["${MAVEN_DIR}"]="https://dlcdn.apache.org/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz"
tool_list["${PYTHON_DIR}"]="https://www.python.org/ftp/python/3.12.4/Python-3.12.4.tgz"
tool_list["${DBEAVER_DIR}"]="https://dbeaver.io/files/dbeaver-ce-latest-linux.gtk.x86_64-nojdk.tar.gz"
tool_list["${ECLIPSE_IDE}"]="https://www.eclipse.org/downloads/download.php?file=/eclipse/downloads/drops4/R-4.27-202303020300/eclipse-SDK-4.27-linux-gtk-x86_64.tar.gz"

index["$ECLIPSE_IDE"]="Eclipse IDE"
index["$JAVA_DIR"]="Java Development Kit (JDK)"
index["$PYTHON_DIR"]="Python"
index["$MAVEN_DIR"]="Maven"
index["$DBEAVER_DIR"]="Dbeaver"

# print menus ----------------------------------------------------------------------------------------------------

show_main_menu() {
  dialog --clear --title "Developer Environment Creator" \
  --menu "Choose an option:" \
  0 0 0 \
  "1" "Backend installation" \
  2>&1 >/dev/tty
}

# install and create ---------------------------------------------------------------------------------------------

download(){
  local path=$1
  local url=$2
  local name=$3

  echo -e "  .downloading:" >> $LOG_FILE
  if [ ! -e "${path}/${name}.tar.gz" ]; then
    {
      sudo wget -q -O "${path}/${name}.tar.gz" "$url"
    } >> "$LOG_FILE" 2>&1

    if [ $? -ne 0 ]; then
      echo "    .error downloading ${name}" >> $LOG_FILE 
      return 1
    fi
    echo "    .${name} downloaded successfully!" >> $LOG_FILE
  else
    echo "    .${name} already downloaded... skipping..." >> $LOG_FILE
  fi
}

extract(){
  local path=$1
  local url=$2
  local name=$3

  echo -e "  .extracting:" >> $LOG_FILE
  if [ -e "${path}/${name}.tar.gz" ]; then
    sudo tar -xzf "${path}/${name}.tar.gz" -C "${path}" > /dev/null 2>&1

    if [ $? -ne 0 ]; then
      echo "    .error extracting ${name}" >> $LOG_FILE
      return 1
    fi
    echo "    .${name} extracted successfully!" >> $LOG_FILE
  else
    echo "    .${name} already extracted... skipping..." >> $LOG_FILE
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
    *"python"*)
      echo "install.sh"
      ;;
    *"dbeaver"*)
      echo "dbeaver.exe"
      ;;
  esac
}

execute_sh_file(){
  local sh_path=$1
  local sh_name=$2

  "$sh_path./$sh_name"
}

create_environment_variable(){
  local path=$1
  local url=$2
  local name=$3

  tool_name=$(config_tool_name $name)
  tool_extension="${tool_name##*.}"
  tool_basename=$(basename "$tool_name" .exe)

  if [ "$tool_extension" == "exe" ]; then
    echo -e "  .creating environment variable:" >> $LOG_FILE

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
            echo "    .error creating ${name} environment variable" >> $LOG_FILE
            return 1
          fi
          echo -e "    .${name} environment variable created successfully!" >> $LOG_FILE
        else
          echo -e "    .${name} environment variable already created... skipping..." >> $LOG_FILE
        fi

        maxdepth=$(( maxdepth + 1 ))
      fi
    done
  else
    sh_path=$(exe_path=$(find "$path" -type f -iname "$tool_name"))
    execute_sh_file $sh_path $tool_name
  fi
}

install(){
  local to_install=("$@")
  echo -e "installing tools...\n" >> $LOG_FILE

  declare -A tools
  for tool in "${to_install[@]}"; do 
    tools["${tool}"]="${tool_list[$tool]}"
  done

  for item in "${!tools[@]}"; do
    path=${item}
    url=${tools[$item]}
    name=$(basename "${path}")
    echo -e "installing ${name}..." >> $LOG_FILE
  
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
    
    echo -e "${name} installed successfully!\n" >> $LOG_FILE
    source ~/.bashrc
  done

  sleep 1
}

create_directories(){
  local directories=("$@")

  echo -e "creating directories:" >> $LOG_FILE

  for dir in "${directories[@]}"; do
    if [ -e \$dir ]; then
      echo "  .dir $dir already created... skipping..." >> $LOG_FILE
      continue
    fi

    sudo mkdir -p "$dir"
    if [ $? -ne 0 ]; then
      echo "  .error creating dir: $dir" >> $LOG_FILE
      continue
    fi 

    echo "  .dir $dir created" >> $LOG_FILE
  done

  echo -e "\nall directories verified successfully!\n" >> $LOG_FILE
  sleep 1
}

backend_installation() {
  dialog --title 'Confirm Installation' \
  --yesno '\nAre you sure that you want to continue with the installation?\n\nThis installation will include:\n\n- Java Development Kit (JDK)\n- Maven\n- Python\n- Eclipse IDE\n- Visual Studio Code\n- Git' \
  15 50 
  
  case $? in
    0)
      dialog --title "Creating environment..." --tailbox $LOG_FILE 30 70 & DIALOG_PID=$!

      directories=(
        "$ECLIPSE_IDE" 
        "$ECLIPSE_WS"
        "$TOOLS_DIR"
        "$PYTHON_DIR"
        "$PROJECTS_DIR"
        "$MAVEN_DIR"
        "$JAVA_DIR"
		"$DBEAVER_DIR"
		)
      create_directories "${directories[@]}"
      sleep 1

	  to_install=("$ECLIPSE_IDE" "$DBEAVER_DIR" "$PYTHON_DIR" "$MAVEN_DIR" "$JAVA_DIR")
      install "${to_install[@]}"
      sleep 1

	  dialog --title 'Installation Finished.' --msgbox 'Installed tools:\n\n- Java Development Kit (JDK)\n- Python\n- Eclipse IDE\n- Maven\n- Dbeaver' 0 0
      return 0
      ;;
    1)
      return 1
      ;;
  esac
}

# main routine ---------------------------------------------------------------------------------------------------

sudo ls /root

touch $LOG_FILE
chmod 777 $LOG_FILE

if ! command -v dialog &> /dev/null; then
  echo "Starting..."
  sudo apt-get update &> /dev/null
  sudo apt-get install -y dialog &> /dev/null
fi

while true; do
  OPTION=$(show_main_menu)
  case $OPTION in
    1)
      backend_installation
      break
      ;;
  esac
done

rm $LOG_FILE
pkill -9 dialog
clear
