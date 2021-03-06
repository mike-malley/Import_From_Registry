use credFinder
GO
/****** Object:  StoredProcedure [dbo].[Populate_Competencies_cache]    Script Date: 10/6/2017 4:10:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
select *
from [ConditionProfile_Competencies_cache]


[Populate_Competencies_cache] 0

[Populate_Competencies_cache] 1

*/


/* =============================================
Description:      Populate_Competencies_cache
Options:

  @CredentialId - optional credentialId. 
				If non-zero will only replace the related row, otherwise replace all

  ------------------------------------------------------
Modifications
16-10-13 mparsons - new

*/

Alter PROCEDURE [dbo].[Populate_Competencies_cache]
		@CredentialId	int = 0
As

SET NOCOUNT ON;

DECLARE
	@debugLevel      int

Set @debugLevel = 4

-- =================================


if @CredentialId > 0 begin
	print 'deleting credential ' + convert(varchar,@CredentialId)
	DELETE FROM [dbo].[ConditionProfile_Competencies_cache]
					WHERE [CredentialId] = @CredentialId

	print 'deleted competencies ' + convert(varchar, @@ROWCOUNT)
	end
else begin
		print 'truncating table'
		truncate table ConditionProfile_Competencies_cache
		end

	--add assessment related
	INSERT INTO [dbo].[ConditionProfile_Competencies_cache]
							([CredentialId]
							--,[ConnectionTypeId]
							--,[EntityConditionProfileRowId]
							,[nodeLevel]
							,SourceEntityTypeId
							,[SourceId]
							,[SourceName]
							,CompetencyFrameworkItemId
							,[Competency]
							,[Description])

	SELECT DISTINCT [CredentialId]
				--,0 as [ConnectionTypeId]
				--,'00000000-0000-0000-0000-000000000000'				As EntityConditionProfileRowId
				,[nodeLevel]
				,3
				,[AssessmentId] As SourceId
				,[Assessment]		As SourceName
				,CompetencyFrameworkItemId
				,[Competency]
				,TargetNodeDescription
			
		FROM [dbo].[ConditionProfile_Assessments_Competencies_Summary]
	--where [CredentialId]= 62
	--where [AssessmentId]= 17
		where (@CredentialId = 0) OR  ([CredentialId] = @CredentialId)

		print 'added assessment competencies ' + convert(varchar, @@ROWCOUNT)

	-- add learning opp related
	INSERT INTO [dbo].[ConditionProfile_Competencies_cache]
							([CredentialId]
							--,[ConnectionTypeId]
							--,[EntityConditionProfileRowId]
							,[nodeLevel]
							,SourceEntityTypeId
							,[SourceId]
							,[SourceName]
							,CompetencyFrameworkItemId
							,[Competency]
							,[Description])

	SELECT DISTINCT [CredentialId]
				--,[ConnectionTypeId]
				--,[RowId]						As EntityConditionProfileRowId
				,[learningOppNode]	as [nodeLevel]
				,7
				,[LearningOpportunityId]	As SourceId
				,[LearningOpportunity]		As SourceName
				,CompetencyFrameworkItemId
				,[Competency]
				,TargetNodeDescription
			
		FROM [dbo].[ConditionProfile_LearningOpp_Competencies_Summary]
		where (@CredentialId = 0) OR  ([CredentialId] = @CredentialId)

		print 'added learning opp competencies ' + convert(varchar, @@ROWCOUNT)

go

grant execute on [Populate_Competencies_cache] to public
go