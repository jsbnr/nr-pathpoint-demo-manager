# Pathpoint Demo Manager

A Terraform-based infrastructure-as-code tool for generating and managing New Relic Pathpoint configurations. This project allows you to define complex customer journey flows with stages, levels, steps, and signals in a structured `terraform.tfvars` file, automatically creating alert policies, conditions, and Pathpoint JSON configurations.

## Overview

This tool simplifies the creation and management of New Relic Pathpoint flows by:

- **Defining customer journeys as code** - Configure your entire Pathpoint flow hierarchy in Terraform
- **Automated alert creation** - Generates New Relic alert policies and conditions for each signal so they can vary in a controlled manner.
- **Pathpoint JSON generation** - Produces ready-to-import Pathpoint configuration files
- **Multi-flow support** - Manage multiple pathpoint flows simultaneously
- **Stable IDs** - Uses UUIDs to maintain consistency when names change
- **Entity integration** - Reference existing New Relic entities or create new alerts on the fly for demonstration purposes.

## Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- New Relic account with API access
- New Relic API key

### Configuration

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Set up the helper script:**

   Copy the appropriate helper script for your platform:

   **For Unix/macOS:**
   ```bash
   cp runtf.sh.sample runtf.sh
   chmod +x runtf.sh
   ```

   **For Windows:**
   ```powershell
   cp runtf.ps1.sample runtf.ps1
   ```

3. **Configure your credentials:**

   Edit the helper script ([runtf.sh](runtf.sh) or [runtf.ps1](runtf.ps1)) and set your New Relic credentials:

   **For Unix/macOS (runtf.sh):**
   ```bash
   export NEW_RELIC_ACCOUNT_ID="YOUR_ACCOUNT_ID"
   export NEW_RELIC_API_KEY="NRAK-YOUR_API_KEY"
   ```

   **For Windows (runtf.ps1):**
   ```powershell
   $terraformNRAccountId = "YOUR_ACCOUNT_ID"
   $terraformAPIKey = "NRAK-YOUR_API_KEY"
   ```

   Note: These helper scripts are in `.gitignore` to prevent accidentally committing credentials.

### Defining Your Pathpoint Flow

The core of this project is the `flows` variable in [terraform.tfvars](terraform.tfvars). Each flow represents a complete customer journey.

#### Hierarchy

Your Pathpoint flow follows this hierarchy:

```
Flow (Customer Journey)
└── Stages (e.g., Marketing, Login, Checkout)
    └── Levels (vertical groupings)
        └── Steps (horizontal groupings)
            └── Signals (individual alerts or entities)
```

#### Signal Types

Signals can be configured in two ways:

**1. Auto-generated Alerts (default):**
```hcl
{
  name  = "Login Service"
  state = "normal"  # MUST be one of: "normal", "warning", or "critical"
}
```
This creates a New Relic alert condition that returns different values based on minutes past the hour. This allows you to control which signals are in normal, warning or critical status.

**Important:** The `state` field MUST be one of the following values:
- `"normal"` - Service operating normally
- `"warning"` - Service experiencing degraded performance
- `"critical"` - Service is down or severely impacted

**2. Existing Entity References:**
```hcl
{
  name  = "Payment Gateway"
  type  = "entity"
  guid  = "YOUR_ENTITY_GUID"
}
```
This references an existing New Relic entity without creating an alert condition to drive its status.

#### Timing Configuration

The `timing` object controls the NRQL alert behavior:

- **minute_threshold**: Minutes after the hour to trigger the specified state
- **critical_value**: Value returned when in critical state
- **warning_value**: Value returned when in warning state  
- **normal_value**: Value returned at all other times

Example: With `minute_threshold = 5`, the alert will return `critical_value` from minute 5 to 59 of each hour.

#### Optional Fields

- **id**: Provide custom UUIDs for flows, stages, levels, or steps to maintain stability - otherwise the ID's are generated and may change if file order is changed.
- **tags**: Apply custom tags to all alert conditions in the flow

## Usage

Use the helper scripts to run Terraform commands with your credentials automatically loaded.

### Initialize Terraform

**For Unix/macOS:**
```bash
./runtf.sh init
```

**For Windows:**
```powershell
.\runtf.ps1
# When prompted, enter: init
```

### Plan Your Changes

**For Unix/macOS:**
```bash
./runtf.sh plan
```

**For Windows:**
```powershell
.\runtf.ps1
# When prompted, enter: plan
```

### Apply Configuration

**For Unix/macOS:**
```bash
./runtf.sh apply
```

**For Windows:**
```powershell
.\runtf.ps1
# When prompted, enter: apply
```

This will:
1. Create New Relic alert policies for each defined flow
2. Generate alert conditions for each signal
3. Create Pathpoint JSON configuration files (e.g., `pathpoint-pizza-delivery-journey.json`)

### Import into Pathpoint

After running `terraform apply`, import the generated JSON file(s) into your New Relic Pathpoint application:

1. Navigate to New Relic Pathpoint
2. Click "Import"
3. Upload the generated `pathpoint-*.json` file

## Helper Scripts

The project includes helper scripts to simplify running Terraform with your credentials:

- [runtf.sh.sample](runtf.sh.sample) - Bash script for Unix/macOS
- [runtf.ps1.sample](runtf.ps1.sample) - PowerShell script for Windows

These scripts automatically set up your New Relic credentials as environment variables and pass them to Terraform. Copy the appropriate sample script for your platform, configure your credentials, and use it to run all Terraform commands (init, plan, apply, etc.).

## Advanced Features

### Multiple Flows

You can define multiple customer journeys in a single configuration:

```hcl
flows = [
  { name = "Web Journey", stages = [...] },
  { name = "Mobile Journey", stages = [...] },
  { name = "API Journey", stages = [...] }
]
```

Each flow gets its own alert policy and Pathpoint JSON file.

### State Management

Terraform maintains state in `terraform.tfstate`. Back up this file regularly, or configure [remote state](https://www.terraform.io/docs/language/state/remote.html) for team collaboration.

### Modifying Existing Flows

When you modify your `terraform.tfvars` file:

- Adding signals creates new alert conditions
- Removing signals deletes alert conditions
- Changing names (with stable IDs) preserves resources
- Changing states updates alert configurations

## Example

See [terraform.tfvars.example](terraform.tfvars.example) for a complete pizza delivery journey example with:

- 7 stages (Marketing → Delivery/Collect)
- Multiple levels per stage
- 50+ signals representing different services
- Mixed states (normal, warning, critical)

## Build Flows with AI
You can generate new flows using AI, try this prompt:

```
Build me an additional pathpoint configuration that models ...insert your description here... Refer to the readme.md and use terraform.tfvars.example for inspiration.
```

## Notes

- Alert conditions use NRQL queries that return different values based on the current time
- Signals without a `guid` will create new alert conditions
- Signals with a `guid` reference existing entities and skip alert creation
- The timing mechanism allows you to simulate different states for demo purposes
- Generated JSON files follow the New Relic Pathpoint v2 schema


