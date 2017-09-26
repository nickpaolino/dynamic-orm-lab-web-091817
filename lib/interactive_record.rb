require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.name.downcase.pluralize
  end

  def self.column_names
    # this queries SQL for the column names and returns an array
    sql = <<-SQL
      PRAGMA table_info(#{self.table_name})
    SQL

    columns = []
    DB[:conn].execute(sql).each do |column|
      columns << column["name"]
    end
    columns
  end

  def initialize(options = {})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|name| name == "id"}.join(", ")
  end

  def values_for_insert
    column_values = []
    self.class.column_names.each do |column|
      column_values << "'#{send(column)}'" unless send(column).nil?
    end
    column_values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE name = ?
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    sql = <<-SQL
      SELECT *
      FROM #{self.table_name}
      WHERE #{attribute.keys.first} = ?
    SQL
    DB[:conn].execute(sql, attribute.values.first)
  end
end
