require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

## 
# Support classes which will be under/used as test data
#

class Order < ActiveRecord::Base
end

class AskMe
  def method_missing(symbol, *args)
    "#{symbol.id2name}_answer"
  end
end

class ReportBuilderUnderForMod
  include RuportReportBuilder
end

class ReportBuilderUnderTestSql
  include RuportReportBuilder

  def rspec_sql_query
    "select * from orders where status = 'paid' order by order_number ASC ;"
  end

  def sort
    {:columns => "order_number", :order => :descending}
  end

  def rspec_object_query
    (1..5).to_a.map{|x| AskMe.new}
  end

  define_report "rspec_sql" do |report, obj|
    report.store "First Name", obj["first_name"]
    report.store "Last Name", obj["last_name"]
    report.store "Order Number", obj["order_number"]
    report.store "Payment Status", obj["status"]
  end

end

class ReportBuilderUnderTestNoSql
  include RuportReportBuilder

  def rspec_object_query
    (1..5).to_a.map{|x| AskMe.new}
  end

  define_report "rspec_object" do |report, obj|
    report.store "Status", obj.status
    report.store "Miles Purchased", obj.miles_purchased
    report.store "Term In Months", obj.term_in_months
  end
end

############
# Let the testing begin!
#

describe "ReportBuilder" do

  it "should raise an ArgumentError if you try to define a report without a query and no default method" do
    lambda {
      ReportBuilderUnderForMod.instance_eval %Q{
          define_report "fail" do |report, o|
            report.store "FOOBAR", o.name
          end
      }
    }.should raise_error(ArgumentError)
  end

  it "should raise an ArgumentError if the report name has a space in it" do
    lambda {
      ReportBuilderUnderForMod.instance_eval %Q{
          define_report "gonna fail", "select * from temp" do |report, o|
            report.store "FOOBAR", o.name
          end
      }
    }.should raise_error(ArgumentError)
  end

  it "should not try to raise an error if you give it a query manually rather than defined as a method" do
    lambda {
      ReportBuilderUnderForMod.instance_eval %Q{
          define_report "noFail", "select * from temp" do |report, o|
            map "FOOBAR", o.name
          end
      }
    }.should_not raise_error(ArgumentError)
  end

  it "should add a report to the list when it defines a report" do
    ReportBuilderUnderTestNoSql.report("rspec_object").should_not be_nil
  end

  it "should be able to return a list of report names" do
    ReportBuilderUnderTestNoSql.report_names.should == ["rspec_object"]
  end

  it "should be able to return a specific report" do
    ReportBuilderUnderTestNoSql.report("rspec_object").should_not be_nil
  end

  it "should respond to the alias of build (alias of build_report)" do
    ReportBuilderUnderTestNoSql.new.should respond_to(:build)
  end


  describe "Report using Objects" do
    before(:each) do
      @report = ReportBuilderUnderTestNoSql.new
    end

    it "should be able to generate a report with the query returning the data" do
      result = @report.build_report
      result.size.should == 5
      4.times {|row|
        result[row][0].should == "status_answer"
        result[row][1].should == "miles_purchased_answer"
        result[row][2].should == "term_in_months_answer"
      }
    end
  end

  describe "Report using SQL" do
    before(:each) do
      ActiveRecord::Base.establish_connection("adapter"=>"sqlite3", "database"=>":memory:") 
      ActiveRecord::Base.logger = Logger.new(File.open('/dev/null', 'a'))   
      ActiveRecord::Base.connection.execute %Q{
        create table orders (
          first_name varchar2(30),
          last_name varchar2(30),
          order_number varchar2(30),
          status varchar2(30)
        );
      }
      
      Order.create!(:first_name => "doug" ,:last_name => "bryant", :order_number => "ABC087" ,:status => "failed")
      Order.create!(:first_name => "john" ,:last_name => "riney", :order_number => "ABC042" ,:status => "pending")
      Order.create!(:first_name => "chris" ,:last_name => "gay", :order_number => "ABC076" ,:status => "paid")
      Order.create!(:first_name => "tom" ,:last_name => "mccall", :order_number => "ABC027" ,:status => "paid")
      Order.create!(:first_name => "kenny" ,:last_name => "roberts", :order_number => "ABC001" ,:status => "paid")
      Order.create!(:first_name => "ben" ,:last_name => "spies", :order_number => "ABC011" ,:status => "paid")
      Order.create!(:first_name => "nicky" ,:last_name => "hayden", :order_number => "ABC069" ,:status => "paid")
      Order.create!(:first_name => "colin" ,:last_name => "edwards", :order_number => "ABC005" ,:status => "paid")
    end

    after(:each) do
      ActiveRecord::Base.connection.execute "drop table orders"
    end

    it "should be able to generate a report with SQL" do
      report = ReportBuilderUnderTestSql.new
      result = report.build_report
      result.size.should == 6
    end

    it "should order the results properly" do
      report = ReportBuilderUnderTestSql.new
      result = report.build_report

      # test that it is descending...
      result[0][2].should == "ABC076"
      result[1][2].should == "ABC069"
      result[2][2].should == "ABC027"
      result[3][2].should == "ABC011"
      result[4][2].should == "ABC005"
      result[5][2].should == "ABC001"
    end

  end

end
