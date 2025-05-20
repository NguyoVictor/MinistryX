#!/bin/bash

#=============================================================================#
#                                                                             #
#                         🔷 MinistryX Deployment 🔷                          #
#                                                                             #
#         Automated installation script for MinistryX Church CRM              #
#                                                                             #
#=============================================================================#

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function for printing section headers
print_section() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ ${YELLOW}$1${BLUE} ${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

# Function for printing status messages
print_status() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Function for printing success messages
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function for printing error messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function for printing warning messages
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check the success of commands
check_success() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$2"
        exit 1
    fi
}

# Check if script is running with sudo privileges
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root or with sudo privileges"
   echo -e "${YELLOW}Try running: sudo $0${NC}"
   exit 1
fi

# Welcome message
clear
echo -e "${PURPLE}
 __  __ _       _     _              __  __
|  \/  (_)_ __ (_)___| |_ _ __ _   _\ \/ /
| |\/| | | '_ \| / __| __| '__| | | |\  / 
| |  | | | | | | \__ \ |_| |  | |_| |/  \ 
|_|  |_|_|_| |_|_|___/\__|_|   \__, /_/\_\\
                               |___/      
${NC}"
echo -e "${YELLOW}====== Church CRM System Deployment ======${NC}\n"

# Check for internet connection
print_status "Checking internet connection..."
ping -c 1 google.com > /dev/null 2>&1
if [ $? -ne 0 ]; then
    print_error "No internet connection detected. Please check your network and try again."
    exit 1
fi
print_success "Internet connection confirmed"

# Create a log file
LOG_FILE="/tmp/ministryx_install_$(date +%Y%m%d_%H%M%S).log"
print_status "Installation log will be saved to: $LOG_FILE"
touch $LOG_FILE

# Check system prerequisites
print_section "Checking System Requirements"
print_status "Verifying system packages..."

# Create a backup directory
BACKUP_DIR="/tmp/ministryx_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
print_status "Created backup directory at $BACKUP_DIR"

# Install prerequisites
print_section "Installing System Dependencies"

# Docker installation with check
print_status "Checking if Docker is installed..."
if command -v docker > /dev/null 2>&1; then
  print_success "Docker is already installed"
  # Check if Docker service is running
  if systemctl is-active --quiet docker; then
    print_success "Docker service is running"
  else
    print_status "Starting Docker service..."
    systemctl start docker >> $LOG_FILE 2>&1
    check_success "Docker service started" "Failed to start Docker service. Check logs at $LOG_FILE"
  fi
else
  print_status "Installing Docker..."
  curl -fsSL https://get.docker.com | bash >> $LOG_FILE 2>&1
  check_success "Docker installed successfully" "Failed to install Docker. Check logs at $LOG_FILE"
  
  # Enable Docker service
  print_status "Enabling Docker service to start on boot..."
  systemctl enable docker >> $LOG_FILE 2>&1
  systemctl start docker >> $LOG_FILE 2>&1
  check_success "Docker service enabled and started" "Failed to enable Docker service. Check logs at $LOG_FILE"
fi


# Update package lists
print_status "Updating package lists..."
apt-get update >> $LOG_FILE 2>&1 || {
  print_warning "Failed to update package lists. Continuing with installation..."
}

# Check if Apache2 is running and stop it
print_section "Checking for Apache Conflicts"

if systemctl is-active --quiet apache2; then
  print_warning "Apache2 is currently running and may conflict with Docker ports"
  print_status "Stopping Apache2 service..."
  systemctl stop apache2 >> $LOG_FILE 2>&1
  check_success "Apache2 service stopped" "Failed to stop Apache2 service. Check logs at $LOG_FILE"

  print_status "Disabling Apache2 to prevent it from starting on boot..."
  systemctl disable apache2 >> $LOG_FILE 2>&1
  check_success "Apache2 service disabled" "Failed to disable Apache2. Check logs at $LOG_FILE"
else
  print_success "Apache2 is not running"
fi


# Check and install PHP
print_status "Checking if PHP is installed..."
if command -v php > /dev/null 2>&1; then
  print_success "PHP is already installed ($(php -r 'echo PHP_VERSION;'))"
else
  print_status "Installing PHP..."
  apt-get install -y php >> $LOG_FILE 2>&1
  check_success "PHP installed successfully" "Failed to install PHP. Check logs at $LOG_FILE"
fi

# Install PHP extensions with version detection
print_status "Installing required PHP extensions..."
if command -v php > /dev/null 2>&1; then
  PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
  EXTENSIONS=("curl" "gd" "mysqli" "zip" "simplexml")
  
  # Check which extensions are missing
  MISSING_EXTENSIONS=()
  for ext in "${EXTENSIONS[@]}"; do
    if ! php -m | grep -q "$ext"; then
      MISSING_EXTENSIONS+=("php$PHP_VERSION-$ext")
    else
      print_success "PHP extension $ext is already installed"
    fi
  done
  
  # Install all missing extensions at once
  if [ ${#MISSING_EXTENSIONS[@]} -gt 0 ]; then
    print_status "Installing missing PHP extensions: ${MISSING_EXTENSIONS[*]}..."
    apt-get install -y ${MISSING_EXTENSIONS[@]} >> $LOG_FILE 2>&1
    check_success "All PHP extensions installed successfully" "Failed to install some PHP extensions. Check logs at $LOG_FILE"
  else
    print_success "All required PHP extensions are already installed"
  fi
else
  print_error "PHP is not installed. Cannot install PHP extensions."
  exit 1
fi

# Node.js installation with check
print_status "Checking if Node.js is installed..."
if command -v node > /dev/null 2>&1; then
  print_success "Node.js is already installed ($(node -v))"
else
  print_status "Installing Node.js..."
  apt-get install -y nodejs >> $LOG_FILE 2>&1
  check_success "Node.js installed successfully" "Failed to install Node.js. Check logs at $LOG_FILE"
fi

# NPM installation with check
print_status "Checking if NPM is installed..."
if command -v npm > /dev/null 2>&1; then
  print_success "NPM is already installed ($(npm -v))"
else
  print_status "Installing NPM..."
  apt-get install -y npm >> $LOG_FILE 2>&1
  check_success "NPM installed successfully" "Failed to install NPM. Check logs at $LOG_FILE"
fi

# Composer installation with check
print_status "Checking if Composer is installed..."
if command -v composer > /dev/null 2>&1; then
  print_success "Composer is already installed ($(composer --version | head -n1))"
else
  print_status "Installing Composer..."
  apt-get install -y composer >> $LOG_FILE 2>&1
  check_success "Composer installed successfully" "Failed to install Composer. Check logs at $LOG_FILE"
fi

# Git installation with check
print_status "Checking if Git is installed..."
if command -v git > /dev/null 2>&1; then
  print_success "Git is already installed ($(git --version))"
else
  print_status "Installing Git..."
  apt-get install -y git >> $LOG_FILE 2>&1
  check_success "Git installed successfully" "Failed to install Git. Check logs at $LOG_FILE"
fi

# Clone the repository
print_section "Setting Up MinistryX"
print_status "Cloning MinistryX repository..."
git clone https://github.com/Iambahati/MinistryX.git >> $LOG_FILE 2>&1
check_success "Repository cloned successfully" "Failed to clone repository. Check logs at $LOG_FILE"

# Navigate to the repository
cd MinistryX
check_success "Changed directory to MinistryX" "Failed to change directory to MinistryX"

# Copy environment file
print_status "Setting up environment configuration..."
cp docker/example.env docker/.env
check_success "Environment file copied" "Failed to copy environment file"

# Ask if user wants to customize the .env file
read -p "$(echo -e ${YELLOW}Do you want to customize the .env file now? [y/N]${NC} )" customize_env
if [[ $customize_env == [Yy]* ]]; then
    print_status "Opening .env file for editing..."
    ${EDITOR:-nano} docker/.env
    print_success "Environment file updated"
else
    print_warning "Using default environment settings. You may need to update them later."
fi

# Create a convenient shortcut script
print_status "Creating convenience script..."
cat > "ministryx-control.sh" <<EOF
#!/bin/bash
# MinistryX Control Script

case "\$1" in
  start)
    npm run docker-dev-start
    ;;
  stop)
    docker compose -f docker/docker-compose.test-php8-apache.yaml down
    ;;
  status)
    docker compose -f docker/docker-compose.test-php8-apache.yaml ps
    ;;
  logs)
    docker compose -f docker/docker-compose.test-php8-apache.yaml logs -f
    ;;
  db)
    docker compose -f docker/docker-compose.test-php8-apache.yaml exec database mysql -u root -pchangeme
    ;;
  *)
    echo "Usage: \$0 {start|stop|status|logs|db}"
    exit 1
esac
EOF
chmod +x ministryx-control.sh
check_success "Control script created" "Failed to create control script"

# Npm install
print_status "Installing npm packages... (this may take a while)"
npm install >> $LOG_FILE 2>&1
check_success "Packages installation completed" "Failed to install node packages. Check logs at $LOG_FILE"

# Verify packages installation
print_status "Verifying npm packages installation..."
if [ -d "node_modules" ] && [ "$(find node_modules -mindepth 1 -maxdepth 1 | wc -l)" -gt 0 ]; then
  # Check if the installed packages match those listed in package.json
  missing_deps=$(npm ls --json 2>/dev/null | grep -c "missing:")
  if [ "$missing_deps" -eq 0 ]; then
    print_success "All packages from package.json have been installed correctly"
  else
    print_warning "Some packages may be missing. Run 'npm ls' manually to check"
  fi
else
  print_error "node_modules directory is empty or doesn't exist. Package installation may have failed"
  exit 1
fi

# Create a temporary .composer directory with the right permissions
COMPOSER_HOME="$(pwd)/.composer"
mkdir -p "$COMPOSER_HOME"
chmod 777 "$COMPOSER_HOME"

# Build code with COMPOSER_ALLOW_SUPERUSER to bypass the root warning
print_status "Building code... (this may take a while)"
COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_HOME="$COMPOSER_HOME" npm run deploy >> $LOG_FILE 2>&1
check_success "Code has been built" "Failed to build code. Check logs at $LOG_FILE"

# Clean up temporary composer home directory
rm -rf "$COMPOSER_HOME"

# Start the Docker environment
print_section "Starting MinistryX Services"
print_status "Starting Docker containers... (this may take a few minutes)"
npm run docker-dev-start >> $LOG_FILE 2>&1
check_success "Docker containers started" "Failed to start Docker containers. Check logs at $LOG_FILE"

# Wait for database to be ready
print_status "Waiting for database to be ready..."
sleep 15

# Execute commands in the database container
print_section "Configuring Database"
print_status "Checking database user and permissions..."

docker compose -f docker/docker-compose.test-php8-apache.yaml exec database bash -c "
apt-get update && apt-get install -y mysql-client &&
mysql -u root -p'changeme' -e \"CREATE USER 'churchcrm'@'%' IDENTIFIED BY 'changeme';\"
mysql -u root -p'changeme' -e \"GRANT ALL PRIVILEGES ON churchcrm.* TO 'churchcrm'@'%';\"
mysql -u root -p'changeme' -e \"FLUSH PRIVILEGES;\"
" >> $LOG_FILE 2>&1

check_success "Database configured" "Failed to configure database. Check logs at $LOG_FILE"

# Final status
print_section "Installation Summary"
print_success "MinistryX setup completed successfully!"
echo -e "${CYAN}----------------------------------------${NC}"
echo -e "${GREEN}✓${NC} Docker and dependencies installed"
echo -e "${GREEN}✓${NC} MinistryX repository cloned"
echo -e "${GREEN}✓${NC} Docker environment configured"
echo -e "${GREEN}✓${NC} Application deployed"
echo -e "${GREEN}✓${NC} Database initialized"
echo -e "${CYAN}----------------------------------------${NC}"

# Print access information
echo -e "\n${YELLOW}Access Information:${NC}"
echo -e "${CYAN}Web Interface:${NC} http://localhost"
echo -e "${CYAN}Mail Server:${NC} http://localhost:8025"
echo -e "${CYAN}Database:${NC} localhost:3306"
echo -e "${CYAN}Control Script:${NC} ./ministryx-control.sh {start|stop|status|logs|db}"

# Print log file location
echo -e "\n${CYAN}Installation log:${NC} $LOG_FILE"

# Print a friendly ending
echo -e "\n${PURPLE}Thank you for installing MinistryX Church CRM!${NC}"
echo -e "${YELLOW}May your ministry be blessed with efficient management.${NC}\n"