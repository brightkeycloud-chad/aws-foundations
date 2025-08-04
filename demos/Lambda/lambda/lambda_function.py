import json
import boto3
from datetime import datetime, timedelta

def lambda_handler(event, context):
    """
    Lambda function to get the top 5 service charges from the current AWS monthly bill
    """
    try:
        # Initialize Cost Explorer client
        ce_client = boto3.client('ce')
        
        # Get current month's date range
        now = datetime.now()
        start_of_month = now.replace(day=1).strftime('%Y-%m-%d')
        
        # Calculate end date (today or end of month, whichever is earlier)
        if now.month == 12:
            next_month = now.replace(year=now.year + 1, month=1, day=1)
        else:
            next_month = now.replace(month=now.month + 1, day=1)
        
        end_date = min(now, next_month - timedelta(days=1)).strftime('%Y-%m-%d')
        
        # Query Cost Explorer for current month's costs by service
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_of_month,
                'End': end_date
            },
            Granularity='MONTHLY',
            Metrics=['BlendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        
        # Extract and sort service costs
        service_costs = []
        
        if response['ResultsByTime']:
            groups = response['ResultsByTime'][0]['Groups']
            
            for group in groups:
                service_name = group['Keys'][0]
                cost_amount = float(group['Metrics']['BlendedCost']['Amount'])
                
                # Only include services with non-zero costs
                if cost_amount > 0:
                    service_costs.append({
                        'service': service_name,
                        'cost': cost_amount
                    })
        
        # Sort by cost (descending) and get top 5
        service_costs.sort(key=lambda x: x['cost'], reverse=True)
        top_5_services = service_costs[:5]
        
        # Calculate total cost
        total_cost = sum(service['cost'] for service in service_costs)
        
        # Create human-readable output
        output_lines = []
        output_lines.append("=" * 60)
        output_lines.append(f"AWS BILLING REPORT - {now.strftime('%B %Y')}")
        output_lines.append("=" * 60)
        output_lines.append(f"Report Period: {start_of_month} to {end_date}")
        output_lines.append(f"Total Monthly Cost: ${total_cost:.2f}")
        output_lines.append("")
        
        if top_5_services:
            output_lines.append("TOP 5 SERVICES BY COST:")
            output_lines.append("-" * 60)
            
            for i, service in enumerate(top_5_services, 1):
                cost = service['cost']
                percentage = (cost / total_cost * 100) if total_cost > 0 else 0
                service_name = service['service']
                
                # Truncate long service names for better formatting
                if len(service_name) > 35:
                    service_name = service_name[:32] + "..."
                
                output_lines.append(f"{i}. {service_name:<35} ${cost:>8.2f} ({percentage:>5.1f}%)")
            
            output_lines.append("-" * 60)
            
            # Add summary statistics
            if len(service_costs) > 5:
                other_services_cost = sum(s['cost'] for s in service_costs[5:])
                other_services_count = len(service_costs) - 5
                other_percentage = (other_services_cost / total_cost * 100) if total_cost > 0 else 0
                
                output_lines.append(f"Other Services ({other_services_count}): ${other_services_cost:>8.2f} ({other_percentage:>5.1f}%)")
                output_lines.append("-" * 60)
            
            output_lines.append(f"Total Services: {len(service_costs)}")
        else:
            output_lines.append("No billing data found for this period.")
        
        output_lines.append("=" * 60)
        
        # Join all lines into a single string
        human_readable_output = "\n".join(output_lines)
        
        return {
            'statusCode': 200,
            'body': human_readable_output
        }
        
    except Exception as e:
        error_output = f"""
============================================================
AWS BILLING REPORT - ERROR
============================================================
Error: {str(e)}
Message: Failed to retrieve AWS billing information

Please check:
- Cost Explorer API permissions
- AWS account billing data availability
- Lambda function logs for detailed error information
============================================================
"""
        return {
            'statusCode': 500,
            'body': error_output
        }
