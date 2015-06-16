#!/usr/bin/env python
#
# This script takes a payments service stats json file as input and outputs a 
# one of the stats below:
#   - total number of payment notifications received;
#   - number of notifications received that indicate a successful payment;
#   - number of notifications received that indicate a rejected payment;
#   - the above to be broken down by Payment Provider - if possible.
#
# The json object in the input file is obtained from payments service metrics 
# endpoint.
#
# Author: Ogonna Iwunze
import argparse
import json
import logging
import os
import sys
import time
import urllib2

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format='%(levelname)s: %(message)s'
)

JSON_FILE = '/var/tmp/payments-service-metrics.json'
METRICS_ENDPOINT = 'http://localhost:3050/metrics'

# Check age of metrics.json file
def metrics_cache_expired(json_file, max_age=600):
    """ 
    Returns Boolean
    
    :arg json_file: metrics cache - a json file
    :arg max_age: maximum age (seconds) of metrics file before its considered expired
    """
    if os.path.exists(json_file):
        age = time.time() - os.stat(json_file).st_ctime
        if age <= max_age: 
            return False

    return True


# refresh metrics.json file if older than max_age
# i.e. make a call to metrics endpoint and save output in metrics.json file
def fetch_metrics(json_file):
    """ 
    Returns boolean
    
    :arg json_file: metrics cache - a json file
    """
    try:
        f = open(json_file, 'w')
        f.write(urllib2.urlopen(METRICS_ENDPOINT).read())
        f.close()
    except Exception as e:
        logging.error("Failed to write metrics to file: \n%s", e)
        return False

    return True


# Read metrics.json file (handle exception)
def payments_metrics(json_file):
    """ 
    Returns dictionary of metrics
    
    :arg json_file: metrics cache - a json file
    """
    try:
        metrics = json.load(open(json_file))
    except Exception as e:
        logging.error("Failed to load json file \n%s", e)
        return False

    return metrics


def total_payment_notifications_per_status(metrics, status):
    """ 
    Returns the sum of payment notifications for a given payment status
    
    :arg metrics: metrics hash object
    :arg status:  payment status e.g. PAID, REJECTED
    """
    total = 0
    for s in metrics['totalsPerStatus']:
        if s['status'] == status: 
            total = s['count']

    return total


# get aggregate metrics of payment notifications received (total, successful & rejected)
def payment_notifications_aggregate(metrics, metric_id):
    """ 
    Returns total count of payment notifications for a given payment metric_id
    
    :arg metrics:   metrics hash object
    :arg metric_id: metric id string e.g. successful and rejected
    """
    if metric_id == 'total':
        logging.debug('total_payment_notifications: %s', metrics['total'])
        return metrics['total']

    if metric_id == 'successful':
        logging.debug('total_successful_payment_notifications: %s',
                        total_payment_notifications_per_status(metrics, 'PAID'))
        return total_payment_notifications_per_status(metrics, 'PAID')

    if metric_id == 'rejected':
        logging.debug('total_rejected_payment_notifications: %s',
                        total_payment_notifications_per_status(metrics, 'REJECTED'))
        return total_payment_notifications_per_status(metrics, 'REJECTED')

    return False



# get the above to be broken down by Payment Provider - if possible.
def notification_count_by_metric_id(method_metrics_hash, metric_id):
    """ 
    Returns count of payment notifications for a given payment metric_id
    
    :arg method_metrics_hash:   metrics hash object of a payment method
    :arg metric_id:  metric id string e.g. successful and rejected
    """
    count = 0
    if metric_id == 'total':
        return method_metrics_hash['count']

    if metric_id == 'successful': 
        status = 'PAID'
    if metric_id == 'rejected': 
        status = 'REJECTED'

    for e in method_metrics_hash['events']:
        if e['status'] == status: 
            return e['count']

    return False


def per_method_payment_notifications(metrics, method_name, metric_id):
    """ 
    Returns count of payment notifications for a given method
    
    :arg metrics:       metrics hash object
    :arg method_name:   metrics hash object of a payment method
    :arg metric_id:     metric id string e.g. successful and rejected
    """
    for m in metrics['methodSummaries']:
        if m['method'] == method_name:
            logging.debug('%s | metric_id: %s', m['method'], metric_id)
            return notification_count_by_metric_id(m, metric_id)

    return False


def discover_payment_methods(metrics):
    """ 
    Returns json object.
    
    :arg metrics:       metrics hash object
    """
    count = 0
    summaries = { 'data': [] }
    for m in metrics['methodSummaries']:
        summaries['data'].append({ 
                                '{#PMNAME}': m['method'],
                                })

    return json.dumps(summaries)


# VISA-SSL | total: 5 | successful: 1 | rejected: 2
# ECMC-SSL | total: 1 | successful: 0 | rejected: 1
# AMEX-SSL | total: 0 | successful: 0 | rejected: 0
# MAESTRO-SSL | total: 0 | successful: 0 | rejected: 0
# CHINAUNIONPAY-SSL | total: 0 | successful: 0 | rejected: 0
# ALIPAY-SSL | total: 0 | successful: 0 | rejected: 0

# payments-service-metrics.py --fetch-metrics --discover
# payments-service-metrics.py --fetch-metrics --payment-method VISA-SSL --metric-id successful
# payments-service-metrics.py --fetch-metrics --aggregate --metric-id $1

##################
## Args Parsing ##
##################
parser = argparse.ArgumentParser(description='Payments Service Stats Parser')

parser.add_argument('--discover', action='store_true', dest='discover', 
        help='Discover payment methods')
parser.add_argument('--metric-id', metavar='METRIC', dest='metric_id', 
        help='Name of metric to obtain')

group1 = parser.add_mutually_exclusive_group()
group1.add_argument('--aggregate', action='store_true', dest='aggregate', 
        help='Print aggregate metrics')
group1.add_argument('--payment-method', metavar='METHOD', dest='payment_method', 
        help='Name of Payment Method to obtain stats for')

group2 = parser.add_mutually_exclusive_group()
group2.add_argument('-f', '--file', metavar='CACHE_FILE', dest='json_file', 
        help='Metrics JSON file')
group2.add_argument('--fetch-metrics', action='store_true', dest='fetch_metrics', 
        help='Get metrics from service metrics endpoint')

args = parser.parse_args()


if __name__ == '__main__':
    opts = vars(args)
    logging.debug("Arguments: %s", opts)

    json_file = JSON_FILE
    if opts['fetch_metrics']:
        if metrics_cache_expired(json_file, 600): 
            logging.debug("Creating new metrics cache file")
            fetch_metrics(json_file)
    else:
        json_file = opts['json_file']

    metrics = payments_metrics(json_file)
    if not metrics:
        sys.exit(1)

    if opts['discover']:
        print discover_payment_methods(metrics)
    else:
        if opts['aggregate']:
            print payment_notifications_aggregate(metrics, opts['metric_id'])
        else:
            print per_method_payment_notifications(metrics, opts['payment_method'], opts['metric_id'])
    
