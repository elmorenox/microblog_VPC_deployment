#!/bin/bash

# Create the start_app.sh file from Terraform input
cat > /home/ubuntu/start_app.sh << 'EOL'
${start_app_script_content}
EOL

# Make it executable
chmod +x /home/ubuntu/start_app.sh

# Optional: Run the script if needed
# /home/ubuntu/start_app.sh