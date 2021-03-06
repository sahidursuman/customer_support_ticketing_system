class User < ApplicationRecord
  include EasilyTypable

  ROLES = ['Customer', 'SupportAgent', 'Admin']
  SIGN_UP_ROLES = ROLES.without('Admin')

  self.inheritance_column = 'role'

  has_many :comments

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :role,
    presence: true,
    inclusion: {
      in: User::ROLES,
      if: lambda {self.role.present?}
    }

  validates :password, length: {minimum: 8}
  validate :password_format

  # note: covered by Cucumber test
  def filtered_tickets(filter=nil)
    filter ||= default_ticket_filter
    query_filter = {}
    case filter
    when 'open'
      query_filter = {status: 'open'}
    when 'closed'
      query_filter = {status: 'closed'}
    when 'all'
      query_filter = {status: ['open', 'closed']}
    end
    query_criteria = query_filter.merge(additional_ticket_query_filter)
    results = Ticket.where(query_criteria)
    [results, filter]
  end

  protected
  def additional_ticket_query_filter
    {}
  end
  def default_ticket_filter
    'all'
  end

  private

  def password_format
    return unless self.password.present?
    unless self.password.match(/\d/)
      self.errors[:password] << 'must include at least one number to be more secure (i.e. 0-9)'
    end
    unless self.password.match(/[\,:!@#%^&*_\-+=.;"']/)
      self.errors[:password] << 'must include at least one symbol to be more secure (i.e. ,:!@#%^&*"_-+=.\';)'
    end
  end
end
