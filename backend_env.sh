#!/bin/bash

# developer environment creator script
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
tool_list["${ECLIPSE_IDE}"]="https://www.eclipse.org/downloads/download.php?file=/eclipse/downloads/drops4/R-4.27-202303020300/eclipse-SDK-4.27-linux-gtk-x86_64.tar.gz"
tool_list["${DBEAVER_DIR}"]="https://dbeaver.io/files/dbeaver-ce-latest-linux.gtk.x86_64-nojdk.tar.gz"

index["$ECLIPSE_IDE"]="Eclipse IDE"
index["$JAVA_DIR"]="Java Development Kit (JDK)"
index["$PYTHON_DIR"]="Python"
index["$MAVEN_DIR"]="Maven"
index["$DBEAVER_DIR"]="Dbeaver"

# print menus ----------------------------------------------------------------------------------------------------


# install and create ---------------------------------------------------------------------------------------------

show_loading_animation() {
  local spin_chars="/-\|"
  while kill -0 "$PID" 2>/dev/null; do
    for ((i=0; i<${#spin_chars}; i++)); do
      echo -ne "\r${spin_chars:$i:1}"
      sleep 0.2
    done
  done
}

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

create_environment_variable(){
  local path=$1
  local name=$2

  echo "  .creating environment variable for ${name}..."
  echo "export ${name}_HOME=${path}" >> ~/.bashrc
  echo "export PATH=\$PATH:${path}" >> ~/.bashrc
  source ~/.bashrc
}

install(){
  local to_install=("$@")
  echo -e "installing tools...\n" >> $LOG_FILE

  for item in "${to_install[@]}"; do
    path=${item}
    url=${tool_list[$item]}
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

    create_environment_variable "$path" "$name"
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

basic_installation() {
  echo "This installation will include:"
  echo "- Java Development Kit (JDK)"
  echo "- Maven"
  echo "- Python"
  echo "- Dbeaver"

  read -p "Are you sure that you want to continue with the installation? (y/n): " confirmation
  if [ "$confirmation" != "y" ]; then
    echo "Installation aborted."
    return 1
  fi

  echo "Creating environment..."
  directories=(
    "$ECLIPSE_IDE" 
    "$ECLIPSE_WS"
    "$TOOLS_DIR"
    "$PYTHON_DIR"
    "$PROJECTS_DIR"
    "$MAVEN_DIR"
    "$JAVA_DIR"
	"$DBEAVER_DIR")
  create_directories "${directories[@]}"

  echo "Installing selected tools..."
  tools=("$JAVA_DIR" "$MAVEN_DIR" "$PYTHON_DIR" "$ECLIPSE_IDE" "$DBEAVER_DIR")
  install "${tools[@]}"
  
  echo "Basic installation completed!"
}

full_installation() {
  echo "Creating environment..."
  directories=(
    "$ANDROID_STUDIO_IDE"
    "$ECLIPSE_IDE"
    "$INTELLIJ_IDE"
    "$VSCODE_IDE"
    "$ANDROID_STUDIO_WS"
    "$INTELLIJ_WS"
    "$VSCODE_WS"
    "$ECLIPSE_WS"
    "$TOOLS_DIR"
    "$PYTHON_DIR"
    "$PROJECTS_DIR"
    "$PHP_DIR"
    "$NODE_DIR"
    "$MAVEN_DIR"
    "$JAVA_DIR"
    "$FLUTTER_DIR"
    "$DART_DIR")
  create_directories "${directories[@]}"

  echo "Installing selected tools..."
  tools=("${!tool_list[@]}")
  install "${tools[@]}"
  
  install_git

  echo "Full installation completed!"
}

custom_installation() {
  choice=$(show_what_to_install_menu)
  if [ "$choice" == "1" ]; then
    ides=$(show_ide_menu)
    IFS=' ' read -r -a selected_ides <<< "$ides"
    for index in "${selected_ides[@]}"; do
      case $index in
        1) install "$VSCODE_IDE" ;;
        2) install "$ECLIPSE_IDE" ;;
        3) install "$INTELLIJ_IDE" ;;
        4) install "$ANDROID_STUDIO_IDE" ;;
      esac
    done
  elif [ "$choice" == "2" ]; then
    tools=$(show_tool_menu)
    IFS=' ' read -r -a selected_tools <<< "$tools"
    for index in "${selected_tools[@]}"; do
      case $index in
        6) install "$NODE_DIR" ;;
        7) install "$PYTHON_DIR" ;;
        8) install "$JAVA_DIR" ;;
        9) install "$MAVEN_DIR" ;;
        10) install "$FLUTTER_DIR" ;;
        11) install "$DART_DIR" ;;
        12) install_git ;;
      esac
    done
  fi

  echo "Custom installation completed!"
}

# main -----------------------------------------------------------------------------------------------------------

basic_installation
#option=$(show_main_menu)

#case "$option" in
#  1) basic_installation ;;
#  *) echo "Invalid option, exiting." ;;
#esac

