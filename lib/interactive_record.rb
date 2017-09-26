require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  # --------- CLASS METHODS ---------
  def self.table_name
    self.to_s.downcase + "s"
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = <<-SQL
            PRAGMA table_info(#{self.table_name})
          SQL
    pragma = DB[:conn].execute(sql)
    # [ {}, {}, {}]

    pragma.collect do |column_hash|
      column_hash["name"]
    end.compact
    # [ "col_1", "col_2", "col_3" ]
  end

  # --------- INSTANCE METHODS ---------

  # options = { key_1: value_1, key_2: value_2 }
  # Student.new(name: "gene", grade: "10")

  # options = {name: "gene", grade: "10"}
  # gene = Student.initialize()
  # gene.name = "gene"
  # gene.grade = "10"
  def initialize(options={})
    options.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  # SELECT * FROM <table_name_for_insert>
  def table_name_for_insert
    self.class.table_name
  end

  # INSERT INTO students (name, grade) VALUES ("gene", "10")
  # INSERT INTO <table_name_for_insert> <col_names_for_insert>
  # [ "id", "name", "grade"]
  def col_names_for_insert
    columns = self.class.column_names   # [ "id", "name", "grade"]
    columns.delete_if{|col| col == "id"} # [ "name", "grade"]
    columns.join(", ") # "name, grade"
  end

  # INSERT INTO <table_name_for_insert> <col_names_for_insert> VALUES <values_for_insert>
  # [ "id", "name", "grade"]
  # gene = Student.new
  # gene.values_for_insert
  # gene.send("grade")
  # gene.grade = "10"
  # values << "10"
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{self.send(col_name)}'" unless self.send(col_name).nil?
    end
    values.join(", ")
  end

  # gene = Student.new
  # gene.table_name_for_insert => students
  # gene.col_names_for_insert => name, grade
  # gene.values_for_insert =>
  def save
    sql = "INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

  # name = "Jan"
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  # hash = {name: "Jan"} OR
  # hash = {grade: 10}
  def self.find_by(hash)
    key = hash.keys[0].to_s
    value = hash.values[0]
    sql = "SELECT * FROM #{self.table_name} WHERE " + key + " = ?"
    DB[:conn].execute(sql, value)
  end
end
