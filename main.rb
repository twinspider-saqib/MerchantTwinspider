# frozen_string_literal: true
require 'csv'
require 'active_support/core_ext/string/filters'
require 'date'
require 'byebug'


@orders = []
@merchants = {}
@day_disbursements = {}

def parse_str_to_date(date)
  DateTime.parse(date)
end

def payment_reference
  rand(36**12).to_s(36) # generates random 12 digit alphanumeric string
end

def calculate_disbursement_count(amount)
  commission = payment_to_merchant = 0

  if amount >= 300
    commission = ((amount / 100.0) * 0.85).round(2)
  elsif amount < 300 && amount >= 50
    commission = ((amount / 100.0) * 0.95).round(2)
  elsif amount < 50
    commission = ((amount / 100.0) * 1.0).round(2)
  end
  payment_to_merchant = (amount - commission).round(2)
  [commission, payment_to_merchant]
end


# to work with less data
def read_first_100k_orders
  puts 'Reading Orders CSV'
  orders = CSV.read('orders.csv', headers: true)
  index = 0
  orders.each do |order_row|
    order = order_row.to_s.squish.split(";")
    @orders[index] = { order_id: index, merchant_reference: order[0], amount: order[1].to_i, created_at: order[2] }
    index += 1
    break if index > 100000
  end
  puts "#{index} Orders found"
end

def read_orders_csv
  puts 'Reading Orders CSV'
  orders = CSV.read('orders.csv', headers: true)
  index = 0
  orders.each do |order_row|
    order = order_row.to_s.squish.split(";")
    @orders[index] = { order_id: index, merchant_reference: order[0], amount: order[1].to_i, created_at: order[2] }
    index += 1
  end
  puts "#{orders.count} Orders found"
end

def read_merchants_csv
  puts 'Reading Merchants CSV'
  merchants = CSV.read('merchants.csv', headers: true)
  merchants.each do |merchant_row|
    merchant = merchant_row.to_s.squish.split(";")
    @merchants[merchant[0]] = {
      reference: merchant[0],
      email: merchant[1],
      live_on: parse_str_to_date(merchant[2]),
      disbursement_frequency: merchant[3],
      minimum_monthly_fee: merchant[4]
    }
  end
  puts "#{merchants.count} Merchants found"
end

def pay_to_merchants
  @merchants.each do |merchant|
    live_on_date = merchant[1][:live_on]
    disbursement_frequency = merchant[1][:disbursement_frequency]
    test_date = parse_str_to_date("2022-10-07")

    if disbursement_frequency == "DAILY" || (live_on_date.day == test_date.day && disbursement_frequency == "WEEKLY")
      merchant_disbursements = {}
      merchant_orders = @orders.select {|order| order[:merchant_reference] == merchant[0]}
      merchant_orders.each do |merchant_order|

        key = payment_reference()
        commission, payment_to_merchant = calculate_disbursement_count(merchant_order[:amount])

        @day_disbursements[key] = {
          merchant_reference: merchant[0],
          order_id: merchant_order[:order_id],
          commission: commission,
          payment_to_merchant: payment_to_merchant,
          payment_reference: key,
          payment_date: Date.today()
        }
      end
    end
  end
end

def print_day_disbursements
  @day_disbursements.each do |day_disbursement|
    puts day_disbursement
  end
end

def start_program
  read_orders_csv
  read_merchants_csv
  pay_to_merchants
  print_day_disbursements
end

start_program()
