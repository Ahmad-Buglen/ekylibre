# -*- coding: utf-8 -*-
{ :eng=>{
    :i18n=>{
      :dir=>'ltr',
      :iso2=>'en',
      :name=>'English',
      :plural=>{
        :keys=> [:one, :other],
        :rule=> lambda { |n| n == 1 ? :one : :other }
      }
    },
    :date => {
      :order => [:month, :day, :year]
    }
  }
}
