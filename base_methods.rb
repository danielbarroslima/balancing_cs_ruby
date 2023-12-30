# frozen_string_literal: true

# DOC: classe para realizar os ajustes nos dados para poder ser executada a ação de balancing.
class BaseMethods
  private

  def obtain_employee_available(customers_successes, employees_not_available)
    employees_available = []
    customers_successes.each do |customers_success|
      next if employees_not_available.include?(customers_success[:id])

      employees_available << customers_success
    end

    employees_available.sort_by { |hash| hash[:score] }
  end

  def obtain_elements_sorted(employees, customers)
    customers_sorted = customers.sort_by { |customer| customer[:score] }
    employee_sorted = employees.sort_by { |employee| employee[:score] }

    { customers_sorted: customers_sorted, employee_sorted: employee_sorted }
  end

  def get_smallest_values_score(sorted_items)
    lowest_customer_score = sorted_items[:customers_sorted].map { |sorted_item| sorted_item[:score] }.min
    lowest_employee_score = sorted_items[:employee_sorted].find do |sorted_item|
      sorted_item[:score] >= lowest_customer_score
    end

    { lowest_customer_score: lowest_customer_score, lowest_employee_score: lowest_employee_score&.dig(:score) }
  end

  def get_index_lowest_score(min_scores, sorted_items)
    index_lowest_scoring_customer = find_index_item(sorted_items[:customers_sorted], min_scores[:lowest_customer_score])
    index_lowest_score_employee   = find_index_item(sorted_items[:employee_sorted], min_scores[:lowest_employee_score])

    { index_lowest_scoring_customer: index_lowest_scoring_customer,
      index_lowest_score_employee: index_lowest_score_employee }
  end

  def find_index_item(sorted_items, min_score)
    sorted_items.find_index { |item| item[:score] == min_score }
  end

  def define_operational_customer_assignment(sorted_customers_and_employees, index_lowest_items)
    employees_eligible_for_assignment = sorted_customers_and_employees[:employee_sorted]
    range_employees_eligible = employees_eligible_for_assignment[index_lowest_items[:index_lowest_score_employee]..]
    customers_for_assignment = sorted_customers_and_employees[:customers_sorted]

    assigning_customer(range_employees_eligible, customers_for_assignment, index_lowest_items)
  end

  def assigning_customer(range_employees_eligible, customers_for_assignment, index_lowest_items)
    range_customers_for_assignment = customers_for_assignment[index_lowest_items[:index_lowest_scoring_customer]..]

    range_employees_eligible.each do |employee|
      customers_for_employee = range_customers_for_assignment.select { |customer| customer[:score] <= employee[:score] }
      employee[:customers] = customers_for_employee
      range_customers_for_assignment = remove_already_assigned_customers(range_customers_for_assignment,
                                                                         customers_for_employee)
    end
  end

  def remove_already_assigned_customers(customers, customers_for_employee)
    customers.reject do |customer|
      customers_for_employee.find { |assigned_employee| assigned_employee[:id] == customer[:id] }
    end
  end

  def inform_employee_with_more_customers(employees_with_customers)
    max_customers = employees_with_customers.map { |hash| hash[:customers].size }.max
    employees_with_much_customers = employees_with_customers.select do |employee|
      employee[:customers].size == max_customers
    end
    return 0 if employees_with_much_customers.size > 1

    employees_with_much_customers.first[:id]
  end
end
