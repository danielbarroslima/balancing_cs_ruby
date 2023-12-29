require 'minitest/autorun'
require 'timeout'
require 'pry'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customers = customers
    @customer_success = customer_success
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    customer_success_available = only_available(@customer_success, @away_customer_success)
    sorted_items = elements_sorted(customer_success_available, @customers) # certo
    min_scores = get_smallest_values(sorted_items) # certo
    return 0 if min_scores[:lowest_employee_score].nil?

    indices_dos_menores = index_lowest_itens(min_scores, sorted_items) # certo
    employees_with_clients = receive_customers(sorted_items, indices_dos_menores)
    employee_with_more_customers(employees_with_clients)
  end

  private

  def index_lowest_itens(min_scores, sorted_items)
    index_lowest_client = sorted_items[:clients_sorted].find_index { |client| client[:score] == min_scores[:lowest_client_score] }
    index_lowest_employee = sorted_items[:employee_sorted].find_index { |employee| employee[:score] == min_scores[:lowest_employee_score] }

    { index_lowest_client: index_lowest_client, index_lowest_employee: index_lowest_employee }
  end

  def get_smallest_values(sorted_items)
    lowest_client_score   = sorted_items[:clients_sorted].map { |sorted_item| sorted_item[:score] }.min
    lowest_employee_score = sorted_items[:employee_sorted].find { |sorted_item| sorted_item[:score] >= lowest_client_score }

    { lowest_client_score: lowest_client_score, lowest_employee_score: lowest_employee_score&.dig(:score) }
  end

  def elements_sorted(employees, clients)
    clients_sorted = clients.sort_by { |client| client[:score] }
    employee_sorted = employees.sort_by { |employee| employee[:score] }

    { clients_sorted: clients_sorted, employee_sorted: employee_sorted }
  end

  def only_available(customers_successes, away_customer_success)
    customers_available = []
    customers_successes.each do |customers_success|
      next if away_customer_success.include?(customers_success[:id])

      customers_available << customers_success
    end

    customers_available.sort_by { |hash| hash[:score] }
  end

  def receive_customers(sorted_clients_and_employees, index_lowest_items)
    sorted_clients_and_employees[:employee_sorted][index_lowest_items[:index_lowest_employee]..].each do |employee|
      customers_for_employee = sorted_clients_and_employees[:clients_sorted][index_lowest_items[:index_lowest_client]..].select { |customer| customer[:score] <= employee[:score] }

      employee[:clients] = customers_for_employee
      sorted_clients_and_employees[:clients_sorted] = remove_already_assigned_customers(sorted_clients_and_employees[:clients_sorted], customers_for_employee)
    end
  end

  def remove_already_assigned_customers(customers, customers_for_employee)
    customers.reject do |customer|
      customers_for_employee.find { |assigned_employee| assigned_employee[:id] == customer[:id] }
    end
  end

  def employee_with_more_customers(employees_with_clients)
    max_clients = employees_with_clients.map { |hash| hash[:clients].size }.max
    employees_with_much_clients = employees_with_clients.select { |employee| employee[:clients].size == max_clients }
    return 0 if employees_with_much_clients.size > 1

    employees_with_much_clients.first[:id]
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(10000.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
