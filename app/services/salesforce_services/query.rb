module SalesforceServices
  class Query
    attr_accessor :table_name, :select, :where, :order, :per, :page

    def initialize table_name
      @table_name = table_name
      @select = "Id"
      @where = ["Id != null"]
      @order = nil
      @per = nil
      @page = nil
    end

    def query
      client.query(sql)
    end

    def select selection
      self.tap { @select = selection }
    end

    def where condition
      self.tap { @where << condition }
    end

    def order order
      self.tap { @order = order }
    end

    def limit integer
      self.tap { @per = integer }
    end

    def offset integer
      self.tap { @page = integer }
    end

    def count
      order(nil).select("COUNT()")
    end

    def first
      limit(1).offset(0)
    end

    def sql
      query = "SELECT #{@select} FROM #{@table_name}"
      query += " WHERE #{@where.join(' AND ')}"
      query += " ORDER BY #{@order}" if @order
      query += " LIMIT #{@per} OFFSET #{(@page - 1) * @per}" if @per && @page

      Arel.sql(query)
    end

    private

    def client
      SalesforceServices::Connect.client
    end
  end
end
