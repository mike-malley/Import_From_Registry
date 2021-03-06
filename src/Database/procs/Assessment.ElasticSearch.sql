USE [credFinder]
GO
--use staging_credFinder
--go
/****** Object:  StoredProcedure [dbo].[Assessment.ElasticSearch]    Script Date: 1/19/2018 9:50:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*

[dbo].[Assessment.ElasticSearch] '', '', 0, 500, NULL


--=====================================================

DECLARE @RC int,@SortOrder varchar(100),@Filter varchar(5000)
DECLARE @StartPageIndex int, @PageSize int, @TotalRows int
--

set @SortOrder = ''
set @SortOrder = 'lastupdated'
set @SortOrder = 'cost_highest'
set @SortOrder = 'org_alpha'
--set @SortOrder = 'cost_lowest'
--set @SortOrder = 'duration_shortest'
--set @SortOrder = 'duration_longest'
-- blind search 

set @Filter = ' base.id in (289) '
--set @Filter = ''

set @StartPageIndex = 1
set @PageSize = 555
--set statistics time on       
EXECUTE @RC = [Assessment.ElasticSearch]
     @Filter,@SortOrder  ,@StartPageIndex  ,@PageSize, @TotalRows OUTPUT

select 'total rows = ' + convert(varchar,@TotalRows)

--set statistics time off     


<QualityAssurance><row SourceEntityBaseId="192" RelationshipTypeId="10" SourceToAgentRelationship="Recognized By" AgentToSourceRelationship="Recognizes" AgentRelativeId="3" AgentName="Elon University"/></QualityAssurance>
*/
--EXEC [dbo].[Assessment.ElasticSearch] '', '', 0, 0, 0

/* =============================================
Description:      Assessment search for elastic load
Options:

  @StartPageIndex - starting page number. 
  @PageSize - number of records on a page
  @TotalRows OUTPUT - total available rows. Used by interface to build a
custom pager
  ------------------------------------------------------
Modifications
18-01-22 mparsons - created from existing search
18-10-06 mparsons - removed [IsQARole]= 1 from QualityAssurance, so that owned and offered by can be filtered. The actual property name should also be changed now! 
*/
ALTER PROCEDURE [dbo].[Assessment.ElasticSearch]
		@Filter           varchar(5000)
		,@SortOrder       varchar(100)
		,@StartPageIndex  int
		,@PageSize        int
		,@TotalRows       int OUTPUT

As

SET NOCOUNT ON;
-- paging
DECLARE
      @first_id               int
      ,@startRow        int
      ,@debugLevel      int
      ,@SQL             varchar(5000)
      ,@OrderBy         varchar(100)

-- =================================

Set @debugLevel = 4


if @SortOrder = 'relevance' set @SortOrder = 'base.Name '
else if @SortOrder = 'alpha' set @SortOrder = 'base.Name '
else if @SortOrder = 'org_alpha' set @SortOrder = 'Organization, base.Name '
else if @SortOrder = 'newest' set @SortOrder = 'base.lastUpdated Desc '
--else if @SortOrder = 'cost_highest' set @SortOrder = 'costs.TotalCost DESC'
--else if @SortOrder = 'cost_lowest' set @SortOrder = 'costs.TotalCost'
else set @SortOrder = 'base.Name '

if len(@SortOrder) > 0 
      set @OrderBy = ' Order by ' + @SortOrder
else
      set @OrderBy = ' Order by base.Name '

--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
      RowNumber         int PRIMARY KEY IDENTITY(1,1) NOT NULL,
      Id int,
      Title             varchar(200)
			,OwningOrganization varchar(300)
)

-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end

  print '@Filter len: '  +  convert(varchar,len(@Filter))
  				--not ideal, but doing a total
					--left join (
					--Select ParentEntityUid, sum(isnull(TotalCost, 0)) As TotalCost from Entity_CostProfileTotal group by ParentEntityUid
					--) costs	on base.RowId = costs.ParentEntityUid	
  set @SQL = 'SELECT  base.Id, base.Name, Organization 
        from [Assessment_Summary] base 
			'
        + @Filter
        
  if charindex( 'order by', lower(@Filter) ) = 0
    set @SQL = @SQL + ' ' + @OrderBy

  print '@SQL len: '  +  convert(varchar,len(@SQL))
  print @SQL

  INSERT INTO #tempWorkTable (Id, Title, OwningOrganization)
  exec (@SQL)
  --print 'rows: ' + convert(varchar, @@ROWCOUNT)
  SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Calculate the range
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

-- ================================= 
SELECT        
	RowNumber, 
	base.Id, 
	base.Name, 
	isnull(base.[Description], '') As [Description],
	isnull(base.SubjectWebpage, '') As SubjectWebpage
	,[DateEffective]
    ,isnull(base.[IdentificationCode],'') As [IdentificationCode]
	--,[SourceToAgentRelationship]
	--,[OrgId]
	--,[Organization]
	,case when Charindex('Placeholder', Isnull([Organization], '')) = 1 then 0
	else [OrgId] end  as [OrgId]
	,case when Charindex('Placeholder', Isnull([Organization], '')) = 1 then ''
	else [Organization] end  as [Organization]
	,base.OwningOrganizationCtid
	,base.Created, 
	base.LastUpdated 
	,e.LastUpdated As EntityLastUpdated
	,base.availableOnlineAt
	,base.AvailabilityListing
	,base.AssessmentExampleUrl
	,base.ProcessStandards
	,base.ScoringMethodExample
	,base.ExternalResearch
	,base.RowId
	,base.EntityStateId
	--,isnull(costs.totalCost,0) As TotalCost
	--,ea.Nbr as AvailableAddresses
	,base.CTID
	,base.CredentialRegistryId

	--ex:  8~Is Preparation For~ceterms:isPreparationFor~2
	,base.ConnectionsList			--actual connection type (no credential info)
	--ex: 8~Is Preparation For~136~MSSC Certified Production Technician (CPT©)~| 8~Is Preparation For~272~MSSC Certified Logistics Technician (CLT©)~
	,base.CredentialsList	--connection type, plus Id, and name of credential

	-- === Connecitions ===================
	,base.RequiresCount
	,base.RecommendsCount
	,base.isRequiredForCount
	,base.IsRecommendedForCount
	,base.IsAdvancedStandingForCount
	,base.AdvancedStandingFromCount
	,base.isPreparationForCount
	,base.PreparationFromCount

	,IsNull(CommonCost.Nbr,0) As CommonCostsCount
	,IsNull(CommonCondition.Nbr,0) As CommonConditionsCount
	,IsNULL(costProfiles.Nbr, 0) As CostProfilesCount
	,IsNULL(conditionProfiles.Nbr, 0) As ConditionProfilesCount
	--remove these
	--,IsNULL(costs.TotalCost, 0) As TotalCostCount
	,0 As TotalCostCount
	,IsNULL(FinancialAid.Nbr, 0) As FinancialAidCount
	,IsNULL(processProfiles.Nbr, 0) As ProcessProfilesCount

	,IsNULL(HasCIP.Nbr, 0) As HasCIPCount
	,IsNULL(HasDuration.Nbr, 0) As HasDurationCount

	--may add the following to the assessment_summary, or a separate view that is clearly only for use with the index build
	,(SELECT DISTINCT ConnectionTypeId ,ConnectionType  ,AssessmentId, isnull(AssessmentName,'') As AssessmentName,   CredentialId, IsNUll(CredentialName,'') As CredentialName, LearningOpportunityId, Isnull(LearningOpportunityName,'') As LearningOpportunityName, credOrgid,credOrganization, asmtOrgid, asmtOrganization, loppOrgid, loppOrganization FROM [dbo].[Entity_ConditionProfilesConnectionsSummary]  WHERE EntityTypeId = 3 
		AND EntityBaseId = base.id 
		FOR XML RAW, ROOT('Connections')) AssessmentConnections

	--,isnull(comps.Nbr,0) as Competencies
	--,0 as Competencies
	 ,(SELECT ISNULL(NULLIF(a.TextValue, ''), NULL) TextValue, a.[CodedNotation], a.CategoryId FROM [dbo].[Entity.SearchIndex] a inner join Entity b on a.EntityId = b.Id inner join Assessment c on b.EntityUid = c.RowId WHERE b.EntityTypeId = 3 AND c.Id = base.Id FOR XML RAW, ROOT('TextValues')) TextValues
	
	,(SELECT DISTINCT acs.[Name], acs.[Description] FROM [dbo].Assessment_Competency_Summary acs  where acs.AssessmentId = base.Id AND acs.AlignmentType = 'assesses' FOR XML RAW, ROOT('AssessesCompetencies')) AssessesCompetencies

	,(SELECT DISTINCT crc.TargetNodeName As Name FROM [dbo].[ConditionProfile_RequiredCompetencies] crc  where crc.ParentEntityBaseId = base.Id AND crc.ParentEntityTypeId = 7 FOR XML RAW, ROOT('RequiresCompetencies')) RequiresCompetencies

	-- [Entity_Subjects] is a union of direct and indirect subjects	: not really applicable to asmts, and lopps, so just the text is used.
	,(SELECT DISTINCT a.[Subject] FROM [Entity_Subjects] a where EntityTypeId = 3 AND a.EntityUid = base.RowId FOR XML RAW, ROOT('SubjectAreas')) SubjectAreas
	--, (SELECT a.[Subject], a.[Source], a.EntityTypeId, a.ReferenceBaseId FROM [dbo].[Entity_Subjects] a WHERE a.EntityTypeId = 3 AND a.EntityUid = base.RowId FOR XML RAW, ROOT('Subjects')) Subjects
	
	, ( SELECT DISTINCT a.CategoryId, a.[PropertyValueId], a.Property, PropertySchemaName  FROM [dbo].[EntityProperty_Summary] a where EntityTypeId= 3 AND CategoryId IN (4, 14, 21, 37, 54, 56) AND base.Id = [EntityBaseId] FOR XML RAW, ROOT('AssessmentProperties')) AssessmentProperties

	,(SELECT a.[CategoryId], a.[ReferenceFrameworkId], a.[Name], a.[SchemaName], ISNULL(NULLIF(a.[CodeGroup], ''), NULL) CodeGroup, a.[CodedNotation] FROM [dbo].[Entity_ReferenceFramework_Summary] a inner join Entity b on a.EntityId = b.Id inner join Assessment c on b.EntityUid = c.RowId where a.[CategoryId] IN (10, 11, 23) AND c.[Id] = base.[Id] FOR XML RAW, ROOT('Frameworks')) Frameworks 


 	--, ( SELECT DISTINCT a.CategoryId, a.TextValue FROM [dbo].[Entity.Reference] a inner join [Entity] b on a.EntityId = b.Id where b.EntityTypeId= 3 AND a.CategoryId = 65 AND base.Id = b.[EntityBaseId] FOR XML RAW, ROOT('Languages')) Languages
	,isnull(Languages.Languages,'') As Languages

					
	--=== QA ==============================
	--,0 as QARolesCount -- is this needed?????
	,base.Org_QAAgentAndRoles
	--this is incorrect, it is all relationships should use RelationshipTypes for consistency
	--renamed from QualityAssurances
	,( SELECT DISTINCT a.[RelationshipTypeId] FROM [dbo].[Entity.AgentRelationship] a inner join Entity b on a.EntityId = b.Id where base.RowId = b.EntityUid FOR XML RAW, ROOT('RelationshipTypes')) RelationshipTypes  
	,'' as QualityAssurances

	--all entity to organization relationships with org information. 
	 ,(SELECT DISTINCT AgentRelativeId As OrgId, AgentName, AgentUrl, EntityStateId, RoleIds as RelationshipTypeIds,  Roles as Relationships, AgentContextRoles FROM [dbo].[Entity.AgentRelationshipIdCSV]
			WHERE EntityTypeId= 3 AND EntityBaseId = base.id 
			FOR XML RAW, ROOT('AgentRelationshipsForEntity')) AgentRelationshipsForEntity
	--now obsolete
	,'' as AgentRelationships

	 --[IsQARole]= 1 and
	,(SELECT DISTINCT [RelationshipTypeId] ,[SourceToAgentRelationship]   ,[AgentToSourceRelationship], Isnull([AgentUrl],'') As AgentUrl  ,[AgentRelativeId], Isnull(AgentName,'') As AgentName, IsQARole,[EntityStateId] FROM [dbo].[Entity_Relationship_AgentSummary]  WHERE  [SourceEntityTypeId] = 3 AND [SourceEntityBaseId] = base.id FOR XML RAW, ROOT('QualityAssurance')) QualityAssurance

	
	,(SELECT b.RowId, b.Id, b.EntityId, a.EntityUid, a.EntityTypeId, a.EntityBaseId, a.EntityBaseName, b.Id AS EntityAddressId, b.Name, b.IsPrimaryAddress, b.Address1, b.Address2, b.City, b.Region, b.PostOfficeBoxNumber, b.PostalCode, b.Country, b.Latitude, b.Longitude, b.Created, b.LastUpdated FROM dbo.Entity AS a INNER JOIN dbo.[Entity.Address] AS b ON a.Id = b.EntityId where a.[EntityUid] = base.[RowId] FOR XML RAW, ROOT('Addresses')) Addresses

		-- addresses for owning org - will only be used if there is no address for the credential
	, (SELECT b.RowId, b.Id, b.EntityId, a.EntityUid, a.EntityTypeId, a.EntityBaseId, a.EntityBaseName, b.Id AS EntityAddressId, b.Name, b.IsPrimaryAddress, b.Address1, b.Address2, b.City, b.Region, b.PostOfficeBoxNumber, b.PostalCode, b.Country, b.Latitude, b.Longitude, b.Created, b.LastUpdated FROM dbo.Entity AS a INNER JOIN dbo.[Entity.Address] AS b ON a.Id = b.EntityId where a.[EntityUid] = base.OwningAgentUid
		FOR XML RAW, ROOT('OrgAddresses')) OrgAddresses

	From #tempWorkTable work 
	Inner join Assessment_Summary base on work.Id = base.Id

  Inner Join Entity e on base.RowId = e.EntityUid
   
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ConditionProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId
	) conditionProfiles	on base.Id = conditionProfiles.EntityBaseId  

	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.CostProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId
	) costProfiles	on base.Id = costProfiles.EntityBaseId  
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.CommonCost] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId
	) CommonCost	on base.Id = CommonCost.EntityBaseId     
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.CommonCondition] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId
	) CommonCondition	on base.Id = CommonCondition.EntityBaseId     
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.FinancialAlignmentProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId 
	) FinancialAid	on base.Id = FinancialAid.EntityBaseId   
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ProcessProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId
	) processProfiles	on base.Id = processProfiles.EntityBaseId      
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.ReferenceFramework] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId 
	) HasCIP	on base.Id = HasCIP.EntityBaseId  
	left join (
	Select b.EntityBaseId, COUNT(*)  As Nbr from [Entity.DurationProfile] a Inner join Entity b ON a.EntityId = b.Id Where b.EntityTypeId = 3  Group By b.EntityBaseId 
	) HasDuration	on base.Id = HasDuration.EntityBaseId  

	left Join ( 
		SELECT     distinct base.Id, 
		CASE WHEN Languages IS NULL THEN ''           WHEN len(Languages) = 0 THEN ''          ELSE left(Languages,len(Languages)-1)     END AS Languages
		From dbo.Assessment base
		CROSS APPLY ( SELECT a.TextValue + '| '
			FROM [dbo].[Entity.Reference] a inner join [Entity] b on a.EntityId = b.Id 
			where b.EntityTypeId= 3 AND a.CategoryId = 65
			and base.Id = b.EntityBaseId FOR XML Path('')  ) D (Languages)
		where Languages is not null
	) Languages on base.Id = Languages.Id

	--left Join (
	--	select EntityId, count(*) as nbr from Assessment_Competency_Summary group by EntityId 
	--	) comps on e.Id = comps.EntityId  
	--left join EntityProperty_AudienceTypeCSV typesCsv on base.Id = typesCsv.EntityId
WHERE RowNumber > @first_id
order by RowNumber 


go
grant execute on [Assessment.ElasticSearch] to public

go
