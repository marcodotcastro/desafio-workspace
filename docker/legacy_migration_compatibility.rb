# frozen_string_literal: true
# Volt Abstraction: Allow legacy migrations in vendor engines (e.g. unico) that inherit directly from ActiveRecord::Migration

module ActiveRecord
  class Migration
    def self.inherited(subclass)
      # Allow legacy migrations without specifying version
    end
  end

  module ConnectionAdapters
    module SchemaStatements
      alias_method :orig_add_index, :add_index
      def add_index(table_name, column_name, options = {})
        orig_add_index(table_name, column_name, options)
      rescue ActiveRecord::StatementInvalid => e
        if e.message =~ /already exists/i
          puts "Notice: index on #{table_name} (#{column_name}) already exists, skipping."
        else
          raise e
        end
      end

      alias_method :orig_add_column, :add_column
      def add_column(table_name, column_name, type, options = {})
        orig_add_column(table_name, column_name, type, options)
      rescue ActiveRecord::StatementInvalid => e
        if e.message =~ /already exists/i
          puts "Notice: column #{column_name} on #{table_name} already exists, skipping."
        else
          raise e
        end
      end

      alias_method :orig_add_foreign_key, :add_foreign_key
      def add_foreign_key(from_table, to_table, options = {})
        orig_add_foreign_key(from_table, to_table, options)
      rescue ActiveRecord::StatementInvalid => e
        if e.message =~ /already exists/i
          puts "Notice: foreign key #{from_table} -> #{to_table} already exists, skipping."
        else
          raise e
        end
      end
    end
  end
end
