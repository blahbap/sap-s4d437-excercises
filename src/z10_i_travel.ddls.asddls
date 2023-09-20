@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Flight Travel'
define root view entity Z10_I_TRAVEL
  as select from z10_travel
  //composition of target_data_source_name as _association_name
{
  key trguid     as Trguid,
      agencynum  as AgencyID,
      travelid   as TravelID,
      trdesc     as TravelDescription,
      customid   as CustomerID,
      stdat      as StartDate,
      enddat     as EndDate,
      status     as Status,
      @Semantics.systemDateTime.lastChangedAt: true
      changed_at as ChangedAt,
      @Semantics.user.lastChangedBy: true
      changed_by as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      loc_changed_at as LocalChangedAt
      //      _association_name // Make association public


}
   
