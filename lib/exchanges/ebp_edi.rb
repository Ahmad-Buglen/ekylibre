module Exchanges

  class EbpEdi < Exchanger


    # Import from simple files EBP.EDI
    def self.import(file, options={})
      File.open(file, "rb:CP1252") do |f|
        header = f.readline.strip
        unless header == "EBP.EDI"
          raise NotWellFormedFileError.new("Start is not valid. Got #{header.inspect}.")
        end
        encoding = f.readline
        f.readline
        owner = f.readline
        started_on = f.readline
        started_on = Date.civil(started_on[4..7].to_i, started_on[2..3].to_i, started_on[0..1].to_i)
        stopped_on = f.readline
        stopped_on = Date.civil(stopped_on[4..7].to_i, stopped_on[2..3].to_i, stopped_on[0..1].to_i)
        ActiveRecord::Base.transaction do
          while 1
            begin
              line = f.readline.gsub(/\n/, '')
            rescue
              break
            end
            unless FinancialYear.find_by_started_at_and_stopped_at(started_on, stopped_on)
              FinancialYear.create!(started_at: started_on, stopped_at: stopped_on)
            end
            line = line.encode("utf-8").split(/\;/)
            if line[0] == "C"
              unless Account.find_by_number(line[1])
                Account.create!(number: line[1], name: line[2])
              end
            elsif line[0] == "E"
              unless journal = Journal.find_by_code(line[3])
                journal = Journal.create!(code: line[3], name: line[3], nature: Journal.natures[-1][1].to_s, closed_at: started_on-1)
              end
              number = line[4].blank? ? "000000" : line[4]
              line[2] = Date.civil(line[2][4..7].to_i, line[2][2..3].to_i, line[2][0..1].to_i)
              unless entry = journal.entries.find_by_number_and_printed_at(number, line[2])
                entry = journal.entries.create!(number: number, printed_at: line[2])
              end
              unless account = Account.find_by_number(line[1])
                account = Account.create!(number: line[1], name: line[1])
              end
              line[8] = line[8].strip.to_f
              if line[7] == "D"
                entry.add_debit(line[6], account, line[8], letter: line[10])
              else
                entry.add_credit(line[6], account, line[8], letter: line[10])
              end
            end
          end
        end
      end
    end

  end

end
