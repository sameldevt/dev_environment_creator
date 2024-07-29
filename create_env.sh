#!/bin/bash

# variables ------------------------------------------------------------------------------------------------------

LOG_FILE="/tmp/devenv_inst_log.txt"
ANDROID_STUDIO_IDE="/opt/dev/ide/androidstudio"
ECLIPSE_IDE="/opt/dev/ide/eclipse"
INTELLIJ_IDE="/opt/dev/ide/intellij"
VSCODE_IDE="/opt/dev/ide/vscode"
ANDROID_STUDIO_WS="/opt/dev/workspace/androidstudio"
INTELLIJ_WS="/opt/dev/workspace/intellij"
VSCODE_WS="/opt/dev/workspace/vscode"
ECLIPSE_WS="/opt/dev/workspace/eclipse"
TOOLS_DIR="/opt/dev/tools"
PYTHON_DIR="/opt/dev/python"
PROJECTS_DIR="/opt/dev/projects"
PHP_DIR="/opt/dev/php"
NODE_DIR="/opt/dev/node"
MAVEN_DIR="/opt/dev/maven"
JAVA_DIR="/opt/dev/java/"
FLUTTER_DIR="/opt/dev/flutter"
DART_DIR="/opt/dev/dart"
GIT=""

# lists ----------------------------------------------------------------------------------------------------------

declare -A tool_list
declare -A index

tool_list["${JAVA_DIR}"]="https://download.java.net/java/GA/jdk22.0.2/c9ecb94cd31b495da20a27d4581645e8/9/GPL/openjdk-22.0.2_linux-x64_bin.tar.gz"
tool_list["${MAVEN_DIR}"]="https://dlcdn.apache.org/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz"
tool_list["${PYTHON_DIR}"]="https://www.python.org/ftp/python/3.12.4/Python-3.12.4.tgz"
tool_list["${FLUTTER_DIR}"]=""
tool_list["${DART_DIR}"]=""
tool_list["${NODE_DIR}"]=""
tool_list["${ANDROID_STUDIO_IDE}"]="https/edgedl/android/studio/ide-zips/2024.1.1.11/android-studio-2024.1.1.11-linux.tar.gz"
tool_list["${ECLIPSE_IDE}"]="https://www.eclipse.org/downloads/download.php?file=/eclipse/downloads/drops4/R-4.27-202303020300/eclipse-SDK-4.27-linux-gtk-x86_64.tar.gz"
tool_list["${INTELLIJ_IDE}"]="https://download.jetbrains.com/idea/ideaIC-2024.1.4.tar.gz?_gl=1*9hygiv*_ga*MTE0OTcwNjUwMi4xNzIxNDA1MTg1*_ga_9J976DJZ68*MTcyMTQwNTE4NC4xLjEuMTcyMTQwNTE5OC4wLjAuMA.."
tool_list["${VSCODE_IDE}"]="https://update.code.visualstudio.com/1.91.1/linux-x64/stable"

index["$VSCODE_IDE"]="Visual Studio Code"
index["$ECLIPSE_IDE"]="Eclipse IDE"
index["$INTELLIJ_IDE"]="IntelliJ IDEA"
index["$ANDROID_STUDIO_IDE"]="Android Studio Android SDK"
index["$JAVA_DIR"]="Java Development Kit (JDK)"
index["$PYTHON_DIR"]="Python"
index["$NODE_DIR"]="Node.js"
index["$MAVEN_DIR"]="Maven"
index["$FLUTTER_DIR"]="Flutter"
index["$DART_DIR"]="Dart"
index["$GIT"]="Git"

# print menus ----------------------------------------------------------------------------------------------------

show_main_menu() {
  dialog --clear --title "Developer Environment Creator" \
  --menu "Choose an option:" \
  0 0 0 \
  "1" "Basic installation" \
  "2" "Full installation" \
  "3" "Custom installation" \
  2>&1 >/dev/tty
}

show_what_to_install_menu() {
  dialog --clear --title "What to install" \
  --menu "Choose what you want to install:" \
  15 50 3 \
  "1" "IDEs" \
  "2" "Tools" \
  2>&1 >/dev/tty
}

show_ide_menu() {
  dialog --clear --checklist "Choose your IDEs (use SPACE to select/deselect):" \
  15 50 4 \
  1 "VSCode" off \
  2 "Eclipse" off \
  3 "IntelliJ" off \
  4 "Android Studio" off \
  2>&1 >/dev/tty
}

show_tool_menu() {
  dialog --clear --checklist "Choose your tools (use SPACE to select/deselect):" \
  15 50 8 \
  6 "Node.js" off \
  7 "Python" off \
  8 "Java" off \
  9 "Maven" off \
  10 "Flutter" off \
  11 "Dart" off \
  12 "Git" off \
  2>&1 >/dev/tty
}

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

install_git(){
  sudo add-apt-repository ppa:git-core/ppa -y
  sudo apt update -y
  sudo apt install git -y
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

config_tool_name(){
  local name=$1

  case "$name" in
    *"java"*)
      echo "java.exe"
      ;;
    *"maven"*)
      echo "mvn.exe"
      ;;
    *"vscode"*)
      echo "code.exe"
      ;;
    *"eclipse"*)
      echo "eclipse.exe"
      ;;
    *"python"*)
      echo "install.sh"
      ;;
    *"android"*)
      echo "studio.sh"
      ;;
    *"idea"*)
      echo "idea.sh"
      ;;
  esac
}

execute_sh_file(){
  local sh_path=$1
  local sh_name=$2

  #"$sh_path./$sh_name"
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

basic_installation() {
  dialog --title 'Confirm Installation' \
  --yesno '\nAre you sure that you want to continue with the installation?\n\nThis installation will include:\n\n- Java Development Kit (JDK)\n- Maven\n- Python\n- Eclipse IDE\n- Visual Studio Code\n- Git' \
  15 50 
  
  case $? in
    0)
      dialog --title "Creating environment..." --tailbox $LOG_FILE 30 70 & DIALOG_PID=$!

      directories=(
        "$ECLIPSE_IDE" 
        "$ECLIPSE_WS"
        "$VSCODE_IDE"
        "$VSCODE_WS"
        "$TOOLS_DIR"
        "$PYTHON_DIR"
        "$PROJECTS_DIR"
        "$MAVEN_DIR"
        "$JAVA_DIR")
      create_directories "${directories[@]}"
      sleep 1

      to_install=("$ECLIPSE_IDE" "$VSCODE_IDE" "$PYTHON_DIR" "$MAVEN_DIR" "$JAVA_DIR")
      install "${to_install[@]}"
      sleep 1

      dialog --title 'Installation Finished.' --msgbox 'Installed tools:\n\n- Java Development Kit (JDK)\n- Python\n- Eclipse IDE\n- Visual Studio Code\n- Git' 0 0
      return 0
      ;;
    1)
      return 1
      ;;
  esac
}

full_installation() {
  dialog --title 'Confirm Installation' \
  --yesno '\nAre you sure that you want to continue with the installation?\n\nThis installation will include:\n\n- Visual Studio Code\n- Eclipse IDE\n- IntelliJ IDEA\n- Android Studio\n- Android SDK\n- Java Development Kit (JDK)\n- Python\n- Node.js\n- Maven\n- Flutter\n- Dart\n- Git' \
  20 70

  case $? in
    0)
      dialog --title "Creating environment..." --tailbox "$LOG_FILE" 30 70 & TAILBOX_PID=$!

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
          "$DART_DIR"
          "$ANDROID_DIR")
      create_directories "${directories[@]}"
      sleep 1

      to_install=(
          "$PYTHON_DIR"
          "$NODE_DIR"
          "$MAVEN_DIR"
          "$JAVA_DIR"
          "$FLUTTER_DIR"
          "$DART_DIR"
          "$ANDROID_DIR"
          "$GIT")

      install "${to_install[@]}"
      sleep 1

      dialog --title 'Installation Finished' --msgbox 'Installed tools:\n\n- Visual Studio Code\n- Eclipse IDE\n- IntelliJ IDEA\n- Android Studio\n- Android SDK\n- Java Development Kit (JDK)\n- Python\n- Node.js\n- Maven\n- Flutter\n- Dart\n- Git' 0 0
      ;;
    1)
      return 1
      ;;
  esac
}

check_choice(){
  local choice=$1
  local to_verify=$2

  for item in $to_verify; do
    if [[ "$choice" == "$item" ]]; then
      return 1
    fi
  done
}

print_choices(){
  local -n list=("$@")
  for item in "${list[@]}"; do
    echo -e "- ${index[$item]}\n"
  done
}

custom_installation() {
  to_install=()
  to_create=()

    CATEGORY=$(show_what_to_install_menu)
    case $CATEGORY in
    1)
      CHOICES=$(show_ide_menu)
      if [ $? -ne 0 ]; then
        return 1
      fi 
      for CHOICE in $CHOICES; do
        case $CHOICE in
          1)
            check_choice "$VSCODE_IDE" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi
            
            to_install+=("$VSCODE_IDE")
            to_create+=("$VSCODE_WS")
            ;;
          2)
            check_choice "$ECLIPSE_IDE" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_install+=("$ECLIPSE_IDE")
            to_create+=("$ECLIPSE_WS")
            ;;
          3)
            check_choice "$INTELLIJ_IDE" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_install+=("$INTELLIJ_IDE")
            to_create+=("$INTELLIJ_WS")
            ;;
          4)
            check_choice "$ANDROID_STUDIO_IDE" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_install+=("$ANDROID_STUDIO_IDE")
            to_create+=("$ANDROID_STUDIO_WS")
            ;;
          *)
            to_install=()
            to_create=()
            return 1
            ;;
        esac
      done
      ;;
    2)
      CHOICES=$(show_tool_menu)
      if [ $? -ne 0 ]; then
        return 1
      fi 
      for CHOICE in $CHOICES; do
        case $CHOICE in
          6)
            check_choice "$NODE_DIR" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_create+=("$NODE_DIR")
            to_install+=("$NODE_DIR")
            ;;
          7)
            check_choice "$PYTHON_DIR" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_create+=("$PYTHON_DIR")
            to_install+=("$PYTHON_DIR")
            ;;
          8)
            check_choice "$JAVA_DIR" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_create+=("$JAVA_DIR")
            to_install+=("$JAVA_DIR")
            ;;
          9)
            check_choice "$MAVEN_DIR" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_create+=("$MAVEN_DIR")
            to_install+=("$MAVEN_DIR")
            ;;
          10)
            check_choice "$FLUTTER_DIR" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_create+=("$FLUTTER_DIR")
            to_install+=("$FLUTTER_DIR")
            ;;
          11)
            check_choice "$DART_DIR" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_create+=("$DART_DIR")
            to_install+=("$DART_DIR")
            ;;
          12)
            check_choice "$GIT" "${to_install[@]}"
            if [ $? -ne 0 ]; then
              continue
            fi

            to_install+=("$GIT")
            ;;
        esac
      done
      ;;
    *)
      to_install=()
      to_create=()
      return 1
      ;;
    esac

      if [ $? -ne 0 ]; then
        to_install=()
        to_create=()
      fi

  choices_text=$(print_choices "${to_install[@]}")

   dialog --title 'Confirm Installation' \
  --yesno "\nAre you sure that you want to continue with the installation?\n\nThis installation will include:\n\n$choices_text"  \
  20 70

  case $? in
    0)
      dialog --title "Creating environment..." --tailbox "$LOG_FILE" 30 70 & TAILBOX_PID=$!

      create_directories "${to_create[@]}"
      sleep 1

      install "${to_install[@]}"
      sleep 1

      dialog --title 'Installation Finished' --msgbox "Installed tools:\n\n- $choices_text" 0 0
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
      basic_installation
      break
      ;;
    2)
      full_installation
      break
      ;;
    3)
      custom_installation
      break
      ;;
    *)
      ;;
  esac
done

rm $LOG_FILE
pkill -9 dialog
clear