

# disable the subscription selector (v. 2.61.0 and up)
az config set core.login_experience_v2=off && az login --tenant <your_tenant_id> && az account set --subscription <your_subscription_name>

