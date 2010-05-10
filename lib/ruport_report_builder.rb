#
# NOTES: When defining reports with define_report method, place the query methods *above* the report definition
#          otherwise the report query will not be in scope
#
#
#  Look at the test to figure out more details about how to use
#  This is the jist of it
#
# class FooReport
#   include RuportReportBuilder
#
#   # Define a sort method iff you want it sorted.  should return a hash similar to below.  default order is ASC. :order is optional
#   def sort
#     {:columns => "quote_number", :order => :descending}
#   end
#
#   Define a query in two ways.  First is with a properly named method.
#   The method should be the same as the report name with _query appended at the end.
#   Queries can return an array of objects such as [Foo.new, Foo.new, Foo.new]
#   or include a sql statement such as select * from foo
#
#   def foo_query
#     .....
#   end
#
#   # Define a report.  This should be done *below* the query definition if applicable because of scoping issues
#   # What ever type of objects are returned from the "query" method
#   define_report("foo") do |row, foo|
#     row.store "Name", foo.name # typical usage for objects returned from query
#     row.store "My Age", foo["age"] # typical usage for if query was sql
#   end
# end
#
# Typical usage
#
# foo_report = Foo.new
# rpt = foo.build_report
# rpt.{as_text|as_html|as_pdf|as_excel}
#

require 'rubygems'
gem 'activerecord'
require 'active_record'
gem 'ruport'
require 'ruport'
require 'ordered_hash'

module RuportReportBuilder

  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    def reports
      @reports ||= RuportReportBuilderUtil::OrderedHash.new
    end

    def report_names
      reports.keys
    end

    def define_report(name, query = nil, &proc)
      raise ArgumentError, "The report name [name] is incorrect.  Report names must not contain a space!" if name.to_s.empty? || name.to_s.include?(" ")
      raise ArgumentError, "You must provide a query or properly name it as a method. Looking for #{query_method_name(name)}. !!If using a query method, make sure it is defined *above* the report definition!!" if query.nil? && !self.instance_methods.include?(query_method_name(name))
      reports[name] = {:query => query, :action => proc}
    end

    def report(name)
      reports[name]
    end

    def query_method_name(name)
      "#{name.gsub(/\s/, "_")}_query"
    end
  end

  module InstanceMethods

    #
    # Returns a Ruport table object you can then call methods on
    #
    def build_report
      main_report, *appended_reports = self.class.report_names

      table_data = generate_report_data(main_report)

      return Ruport::Data::Table.new if table_data.empty?

      # build the table and set the column names based on the data from the "Primary" report
      table = Ruport::Data::Table.new(:column_names => table_data.first.keys, :data => table_data.map{|d| d.values})


      appended_reports.each do |rpt|
        addl_rpt_data = generate_report_data(rpt)
        addl_rpt_data.each{|row| table << row}
      end
      do_sort(table)
    end
    alias :build :build_report

    protected

    def generate_report_data(rpt)
      if data = execute_query_for(rpt)
        action = self.class.report(rpt)[:action]
        return data.map do |d|
          hash = RuportReportBuilderUtil::OrderedHash.new
          action.call(hash, d)
          hash
        end
      else
        nil
      end
    end

    def do_sort(table)
      if self.respond_to?(:sort)
        sort_by = self.sort
        if sort_by.kind_of?(Hash)
          table = table.sort_rows_by(sort_by[:columns], :order => sort_by[:order])
        else
          raise ArgumentError, "Sorting must return a hash!"
        end
      else
        table
      end
    end

    def execute_query_for(report)
      rpt = self.class.report(report)
      if rpt[:query].nil?
        query = self.send self.class.query_method_name(report).to_sym
      else
        query = rpt[:query]
      end

      if query.kind_of?(Array)
        result = query
      else
        result = ActiveRecord::Base.connection.execute query
      end

      result
    end

  end

end

