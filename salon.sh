#!/bin/bash

# Function to execute psql with predefined options
salonpsql() {
  psql --username=freecodecamp --dbname=salon --tuples-only --command="$@"
}

# Function to display services
display_services() {
  echo "Welcome to My Salon, how can I help you?"
  # Query the database for services and display them
  salonpsql "SELECT service_id, name FROM services;" | \
  while IFS='|' read -r service_id service_name; do
    # Remove any leading or trailing whitespace from service_id and service_name
    service_id=$(echo "$service_id" | tr -d '[:space:]')
    service_name=$(echo "$service_name" | tr -d '[:space:]')
    # Print service_id and service_name
    echo "$service_id) $service_name"
  done | sed '$s/)//'  # Remove the extra parentheses from the last line
}

# Display welcome message and list of services
echo -e "\n~~~~~ MY SALON ~~~~~\n"
display_services

# Prompt for input
echo "Please select a service by entering its number: "
read SERVICE_ID_SELECTED

# Check if the entered value is a valid integer
if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
  # Check if the selected service exists
  if salonpsql "SELECT COUNT(*) FROM services WHERE service_id = $SERVICE_ID_SELECTED" | grep -q "1"; then

    echo "Enter customer phone number: "
    read CUSTOMER_PHONE

    # Check if the customer already exists
    if ! salonpsql "SELECT COUNT(*) FROM customers WHERE phone = '$CUSTOMER_PHONE'" | grep -q "1"; then
      # If the customer doesn't exist, prompt for customer name and insert into the database
      echo "Enter customer name: "
      read CUSTOMER_NAME

      # Insert new customer
      salonpsql "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME','$CUSTOMER_PHONE')"
    fi
    
    # Prompt for appointment time
    echo "Enter appointment time: "
    read SERVICE_TIME
    
    # Retrieve the customer ID
    CUSTOMER_ID_SELECTED=$(salonpsql "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    
    # Insert appointment into the database
    salonpsql "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID_SELECTED, $SERVICE_ID_SELECTED, '$SERVICE_TIME')"
    
    # Retrieve selected service name
    SERVICE_NAME=$(salonpsql "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
    
    # Appointment is successfully added message 
    echo -e "I have put you down for a$SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  else
    # If the selected service doesn't exist, prompt again
    echo -e "\nService number $SERVICE_ID_SELECTED does not exist. Please select a valid service.\n"
    display_services  # Show the list of services again
  fi
else
  # If invalid input, prompt again
  echo -e "\nInvalid input. Please enter a valid service number.\n"
  display_services  # Show the list of services again
fi
